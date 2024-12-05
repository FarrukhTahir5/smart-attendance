import time
from fastapi import FastAPI, UploadFile, File, Form
from typing import List
import os
import cv2
import numpy as np
from mtcnn import MTCNN
from keras_facenet import FaceNet
from datetime import datetime
import pickle
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import datetime
import asyncio
import logging
import pickle
from typing import List

# Set up logging configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


from fastapi.staticfiles import StaticFiles


app = FastAPI()

# Initialize MTCNN and FaceNet
mtcnn = MTCNN()
facenet = FaceNet()

# Base storage directory
BASE_DIR = "storage"
os.makedirs(BASE_DIR, exist_ok=True)

# Serve the "attendance" directory as static files
attendance_static_dir = os.path.join(BASE_DIR, "attendance")
os.makedirs(attendance_static_dir, exist_ok=True)
app.mount("/static", StaticFiles(directory=attendance_static_dir), name="static")
# Add CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins; use specific origins in production
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)

@app.post("/upload-student-image")
async def upload_student_image(
    name: str = Form(...),
    rollno: str = Form(...),
    program: str = Form(...),
    batch_number: str = Form(...),
    file: UploadFile = File(...)
):        
    # Create directory for the batch and program
    student_dir = f"{BASE_DIR}/{"batches"}/{batch_number}/{program}/{rollno}"
    photos_dir = f"{student_dir}/photos"
    os.makedirs(photos_dir, exist_ok=True)

    # Process each uploaded file
    file_path = f"{photos_dir}/{file.filename}"
    with open(file_path, "wb") as f:
        f.write(await file.read())
   
    return {
        "message": "file uploaded"
    }



@app.post("/register")
async def register_student(
    name: str = Form(...),
    rollno: str = Form(...),
    batch_number: str = Form(...),
    program: str = Form(...),
    files: List[UploadFile] = File(...),
):
    try:
        # Log all received data
        print("Received data:", {
            "name": name, 
            "rollno": rollno, 
            "batch_number": batch_number, 
            "program": program,
            "files": [file.filename for file in files]
        })
        
        print(f"Received name: {name}, rollno: {rollno}, batch_number: {batch_number}, program: {program}")
        print(f"Received files: {[file.filename for file in files]}")
    except Exception as e:
        print("Error parsing request:", e)
        return {"error": "Invalid data received"}
    
    # Create directory for the batch and program
    student_dir = f"{BASE_DIR}/batches/{batch_number}/{program}/{rollno}"
    photos_dir = f"{student_dir}/photos"
    os.makedirs(photos_dir, exist_ok=True)

    # This will store the embeddings and roll number pairs
    stored_embeddings = []
    rollnos = []

    # Process each uploaded file
    for file in files:
        file_path = f"{photos_dir}/{file.filename}"
        with open(file_path, "wb") as f:
            f.write(await file.read())

        # Detect faces and compute embeddings
        image = cv2.imread(file_path)
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        faces = mtcnn.detect_faces(image_rgb)

        if not faces:
            return {"error": f"No face detected in {file.filename}"}

        for face in faces:
            x, y, w, h = face["box"]
            face_crop = image_rgb[y:y+h, x:x+w]
            embedding = facenet.embeddings([face_crop])[0]
            stored_embeddings.append(embedding)
            rollnos.append(rollno)  # Store the roll number for each embedding

    # Save individual embeddings for the student in the same format
    embeddings_path = f"{student_dir}/embeddings.pkl"
    with open(embeddings_path, "wb") as f:
        pickle.dump((stored_embeddings, rollnos), f)

    # Update batch-level embeddings
    batch_embeddings_path = f"{BASE_DIR}/batches/{batch_number}/{program}/batch_embeddings.pkl"
   
    all_embeddings = ([], [])

    if os.path.exists(batch_embeddings_path):
        with open(batch_embeddings_path, "rb") as f:
            all_embeddings = pickle.load(f)

    current_embeddings, current_rollnos = all_embeddings

    current_embeddings.extend(stored_embeddings)
    current_rollnos.extend(rollnos)

    # Save the updated batch embeddings
    with open(batch_embeddings_path, "wb") as f:
        pickle.dump((current_embeddings, current_rollnos), f)

    return {"message": f"Student {name} (Roll No: {rollno}) registered successfully in Batch {batch_number} for {program}."}


# Helper functions
def resize_image_aspect_ratio(image, max_width=4000, max_height=3000):
    """Resize the image to fit within a max width and height, maintaining aspect ratio."""
    height, width = image.shape[:2]
    scale_width = max_width / width
    scale_height = max_height / height
    scale_factor = min(scale_width, scale_height)
    new_width = int(width * scale_factor)
    new_height = int(height * scale_factor)
    return cv2.resize(image, (new_width, new_height))

def extract_faces(image):
    """Extract faces from the uploaded image using MTCNN."""
    faces = mtcnn.detect_faces(image)
    extracted_faces = [(image[y:y+h, x:x+w], (x, y, x+w, y+h)) for x, y, w, h in [face['box'] for face in faces]]
    return extracted_faces

def recognize_faces_batch(embeddings, class_embeddings, threshold=0.92):
    """Batch comparison of embeddings for face recognition."""
    embeddings_list, names_list = class_embeddings
    results = []
    for embedding in embeddings:
        distances = np.linalg.norm(embeddings_list - embedding, axis=1)
        min_dist_idx = np.argmin(distances)
        if distances[min_dist_idx] < threshold:
            results.append(names_list[min_dist_idx])
        else:
            results.append("Unknown")
    return results

async def run_in_executor(func, *args):
    """Run CPU-bound function in a separate thread."""
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, func, *args)

async def read_and_decode_file(file_data):
    """Read and decode image in a separate thread."""
    return await asyncio.to_thread(cv2.imdecode, np.frombuffer(file_data, np.uint8), cv2.IMREAD_COLOR)

# Main API endpoint
@app.post("/mark-attendance")
async def mark_attendance(
    dept: str = Form(...),
    program: str = Form(...),
    sem: str = Form(...),
    class_: str = Form(...),
    batch_number: str = Form(...),
    file: UploadFile = File(...),
):
    try:
        start_time = time.time()  # Start tracking total execution time

        # Step 1: Read uploaded file
        file_data = await file.read()
        image = await read_and_decode_file(file_data)

        # Step 2: Resize image
        image = resize_image_aspect_ratio(image)

        # Step 3: Load class embeddings
        batch_embeddings_path = f"{BASE_DIR}/batches/{batch_number}/{program}/batch_embeddings.pkl"
        if not os.path.exists(batch_embeddings_path):
            return {"message": "No embeddings found for this class"}

        with open(batch_embeddings_path, "rb") as f:
            class_embeddings = pickle.load(f)

        # Step 4: Extract faces from the image in parallel
        faces = await run_in_executor(extract_faces, image)

        if not faces:
            return {"message": "No faces detected in the group photo"}

        # Step 5: Generate embeddings in parallel
        face_images = [face_img for face_img, _ in faces]
        embeddings = await asyncio.gather(
            *[run_in_executor(facenet.embeddings, [face_img]) for face_img in face_images]
        )
        embeddings = np.array([embedding[0] for embedding in embeddings])

        # Step 6: Recognize faces
        recognized_students = recognize_faces_batch(embeddings, class_embeddings)

        # Step 7: Annotate image with results
        annotated_image = image.copy()
        for (face_img, bbox), recognized_student in zip(faces, recognized_students):
            x1, y1, x2, y2 = bbox
            cv2.rectangle(annotated_image, (x1, y1), (x2, y2), (0, 255, 0), 2)
            label = recognized_student if recognized_student != "Unknown" else "Unknown"
            cv2.putText(annotated_image, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (36, 255, 12), 2)

        # Step 8: Save annotated image
        annotated_image_filename = f"annotated_{file.filename}"
        annotated_image_path = os.path.join(attendance_static_dir, annotated_image_filename)
        compression_params = [cv2.IMWRITE_JPEG_QUALITY, 70]
        await asyncio.to_thread(cv2.imwrite, annotated_image_path, annotated_image, compression_params)

        # Step 9: Timestamp for attendance
        current_datetime = datetime.datetime.now()
        formatted_datetime = current_datetime.strftime("%Y-%m-%d %I:%M %p")
        attendance_meta = f"{formatted_datetime}"

        # Final response
        return {
            "message": "Attendance marked successfully",
            "recognized_students": recognized_students,
            "annotated_image_url": f"/static/{annotated_image_filename}",
            "attendance_meta": attendance_meta
        }

    except Exception as e:
        return {"error": str(e)}