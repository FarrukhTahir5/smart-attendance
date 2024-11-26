from fastapi import FastAPI, UploadFile, File, Form
from typing import List, Optional
import os
import cv2
import numpy as np
from mtcnn import MTCNN
from keras_facenet import FaceNet
from datetime import datetime
import pickle
import json
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Initialize MTCNN and FaceNet
mtcnn = MTCNN()
facenet = FaceNet()

# Base storage directory
BASE_DIR = "storage"
os.makedirs(BASE_DIR, exist_ok=True)

@app.get("/dropdown-data")
async def dropdown_data():
    data = {
        "departments": {
            "Computer Science": {
                "programs": {
                    "BS CS": ["Fall 2020", "Spring 2021"],
                    "MS CS": ["Spring 2021"]
                },
                "classes": {
                    "Fall 2020": [
                        "CS101 - Group A - Dr. Smith",
                        "CS101 - Group B - Dr. Jane"
                    ],
                    "Spring 2021": [
                        "CS102 - Group A - Dr. John"
                    ]
                }
            },
            "Electrical Engineering": {
                "programs": {
                    "BS EE": ["Fall 2020"],
                    "MS EE": ["Spring 2021"]
                },
                "classes": {
                    "Fall 2020": ["EE101 - Group A - Dr. Brown"],
                    "Spring 2021": ["EE102 - Group A - Dr. Alice"]
                }
            }
        }
    }
    return data
# Add CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins; use specific origins in production
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)

# Your existing routes here
@app.post("/register")
async def register_student(
    name: str = Form(...),
    rollno: str = Form(...),
    dept: str = Form(...),
    program: str = Form(...),
    sem: str = Form(...),
    class_: str = Form(...),
    files: List[UploadFile] = File(...)
):
    try:
        print(f"Received name: {name}, rollno: {rollno}, dept: {dept}, program: {program}, sem: {sem}, class: {class_}")
        print(f"Received files: {[file.filename for file in files]}")
    except Exception as e:
        print("Error parsing request:", e)
        return {"error": "Invalid data received"}
    student_dir = f"{BASE_DIR}/{dept}/{program}/{sem}/{class_}/{rollno}"
    photos_dir = f"{student_dir}/photos"
    os.makedirs(photos_dir, exist_ok=True)

    embeddings = []

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
            embeddings.append(embedding)

    # Save individual embeddings for the student
    embeddings_path = f"{student_dir}/embeddings.pkl"
    with open(embeddings_path, "wb") as f:
        pickle.dump(embeddings, f)

    # Update class-level embeddings
    class_embeddings_path = f"{BASE_DIR}/{dept}/{program}/{sem}/{class_}/class_embeddings.pkl"
    all_embeddings = {}
    if os.path.exists(class_embeddings_path):
        with open(class_embeddings_path, "rb") as f:
            all_embeddings = pickle.load(f)

    all_embeddings[rollno] = embeddings
    with open(class_embeddings_path, "wb") as f:
        pickle.dump(all_embeddings, f)

    return {"message": f"Student {name} registered successfully"}


@app.post("/mark-attendance")
async def mark_attendance(
    dept: str = Form(...),
    program: str = Form(...),
    sem: str = Form(...),
    class_: str = Form(...),
    file: UploadFile = File(...)
):
    try:
        print(f"Received: dept={dept}, program={program}, sem={sem}, class_={class_}")
        print(f"Received file: {file.filename}")
    except Exception as e:
        print("Error:", e)
        return {"error": "Invalid data received"}
    class_dir = f"{BASE_DIR}/{dept}/{program}/{sem}/{class_}"
    attendance_dir = f"{class_dir}/attendance"
    os.makedirs(attendance_dir, exist_ok=True)

    # Save group photo
    file_path = f"{class_dir}/{file.filename}"
    with open(file_path, "wb") as f:
        f.write(await file.read())

    # Detect faces in group photo
    image = cv2.imread(file_path)
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    faces = mtcnn.detect_faces(image_rgb)

    if not faces:
        return {"message": "No faces detected in the group photo"}

    # Load class embeddings
    class_embeddings_path = f"{class_dir}/class_embeddings.pkl"
    if not os.path.exists(class_embeddings_path):
        return {"message": "No embeddings found for this class"}

    with open(class_embeddings_path, "rb") as f:
        class_embeddings = pickle.load(f)

    recognized_students = []

    for face in faces:
        x, y, w, h = face["box"]
        face_crop = image_rgb[y:y+h, x:x+w]
        embedding = facenet.embeddings([face_crop])[0]

        # Compare with class embeddings
        for rollno, stored_embeddings in class_embeddings.items():
            distances = [np.linalg.norm(embedding - stored) for stored in stored_embeddings]
            if min(distances) < 0.9:  # Recognition threshold
                recognized_students.append(rollno)
                break

    # Save attendance for the day
    today = datetime.today().strftime('%Y-%m-%d')
    attendance_file = f"{attendance_dir}/{today}.json"
    with open(attendance_file, "w") as f:
        json.dump({"date": today, "present": recognized_students}, f)

    return {"recognized_students": recognized_students}

from urllib.parse import unquote

@app.get("/attendance")
async def get_attendance(
    dept: str,
    program: str,
    sem: str,
    class_: str,
    date: str
):
    dept = unquote(dept)
    program = unquote(program)
    sem = unquote(sem)
    class_ = unquote(class_)
    date = unquote(date)

    print(f"Decoded Department: {dept}")
    print(f"Decoded Program: {program}")
    print(f"Decoded Semester: {sem}")
    print(f"Decoded Class: {class_}")
    print(f"Decoded Date: {date}")

    attendance_dir = f"{BASE_DIR}/{dept}/{program}/{sem}/{class_}/attendance"
    if not os.path.exists(attendance_dir):
        return {"message": "No attendance records found"}

    if date:
        attendance_file = f"{attendance_dir}/{date}.json"
        if os.path.exists(attendance_file):
            with open(attendance_file, "r") as f:
                return json.load(f)
        else:
            return {"message": f"No attendance record found for {date}"}
    else:
        records = []
        for filename in os.listdir(attendance_dir):
            with open(f"{attendance_dir}/{filename}", "r") as f:
                records.append(json.load(f))
        return records

