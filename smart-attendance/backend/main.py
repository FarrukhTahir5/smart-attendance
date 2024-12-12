from pathlib import Path
from fastapi import FastAPI, UploadFile, File, Form, Depends, HTTPException, status
from typing import List
import os
import cv2
from fastapi.responses import JSONResponse
import numpy as np
from mtcnn import MTCNN
from keras_facenet import FaceNet
from datetime import datetime,timedelta
import pickle
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import logging
import pickle
from typing import List,Optional
import re

import jwt
import time

import pandas as pd

from fastapi.security import OAuth2PasswordRequestForm,OAuth2PasswordBearer
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import bcrypt
from sqlalchemy.orm import Session
from fastapi.staticfiles import StaticFiles

# Set up logging configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)



app = FastAPI()

# Initialize MTCNN and FaceNet
mtcnn = MTCNN()
facenet = FaceNet()

# Base storage directory
BASE_DIR = "storage"
STORAGE_PATH = "storage/UsersData" # where users are stored
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

# Helper function to hash passwords
def hash_password(plain_password: str) -> str:
    return bcrypt.hashpw(plain_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

# Function to create a demo user
def create_demo_user(db: Session):
    existing_user = get_user_by_email(db, "demo@test.com")
    if existing_user:
        logger.info(f"Demo user already exists with email {"demo@test.com"}.")
        return existing_user
    else:
        hashed_password = hash_password("abc123")
        new_user = User(email="demo@test.com", hashed_password=hashed_password)
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        logger.info(f"Demo user created with email {"demo@test.com"}.")
        return new_user

# Database URL (SQLite file-based DB)
DATABASE_URL = "sqlite:///./database.db"

# Secret key for JWT encoding/decoding
SECRET_KEY = "eyZhDGciOipIUzI1NiIsILR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibgltPSI6IkpvaG4gRG9lIiwiaWF0IjoxNTO2MjM5MDIyfQ.SflKxwRJSMeKKF2QT8fwpMeJf36POk6yJV_adQssw5c"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30  # Token expiration time in minutes

# SQLAlchemy Database setup
Base = declarative_base()
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Helper function to create a JWT token
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# OAuth2PasswordBearer instance for token-based authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# Database models
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)

# Create tables when the server starts
@app.on_event("startup")
def on_startup():
    # Create the database tables if they do not exist
    Base.metadata.create_all(bind=engine)
    # Create a database session
    db = SessionLocal()
    try:
        # Create the demo user
        create_demo_user(db)
    finally:
        db.close()


# Pydantic models for request and response validation
class UserLogin(BaseModel):
    email: str
    password: str

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Helper function to verify passwords
def verify_password(plain_password, hashed_password):
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

# Function to get user by email
def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

# Login endpoint - returns a JWT token
@app.post("/login")
async def login(user: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    db_user = get_user_by_email(db, user.username)  # 'username' is the email in this case
    if not db_user or not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    # Create JWT token
    access_token = create_access_token(data={"sub": db_user.email})
    return {"access_token": access_token, "token_type": "bearer"}

# Dependency to get the current user from the token
def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        # Decoding the JWT token
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except jwt.PyJWTError as e:
        raise credentials_exception
    return email


# Pydantic model for course data
class Course(BaseModel):
    course_name: str
    batch_number: str



# Pydantic model to represent a course
class UserCourse(BaseModel):
    className: str
    department: str
    program: str
    batch: str
    semester: str


# API endpoint to fetch the list of courses for the current user
@app.get("/courses", response_model=List[UserCourse])
async def get_courses(current_user: str = Depends(get_current_user)):
    print(current_user)
    user_courses_path = Path("./storage/UsersData") / current_user
    print(f"Looking for courses at: {user_courses_path.resolve()}")

    if not user_courses_path.exists():
        raise HTTPException(status_code=404, detail="User data not found")

    print(user_courses_path)
    courses = []
    # Iterate over each course folder for the user
    for course_folder in user_courses_path.iterdir():
        if course_folder.is_dir():
            try:
                print(course_folder)

                # Extract course details from folder name
                folder_name = course_folder.name
                course_name, batch_program = folder_name.split("_")
                batch, program = batch_program.split("-")
                department = "Unknown"  # Assume department is unknown or fetch it from other means
                semester = "Unknown"  # You can also get this from other metadata, if necessary

                # Add course to the list
                courses.append(UserCourse(
                    className=course_name,
                    department=department,
                    program=program,
                    batch=batch,
                    semester=semester
                ))

            except ValueError as e:
                # Handle any folder naming errors gracefully
                continue

    return courses

# API endpoint to add a course
@app.post("/add-course/")
async def add_course(course: Course, token: str = Depends(oauth2_scheme)):
    logger.info("Token received:", token)
    
    # Try getting the current user (email) from the token
    current_user = get_current_user(token)
    print("Current user:", current_user)

    
    # Verify that the current user is a valid email
    if current_user and not is_valid_email(current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid user email"
        )
    
    # Create the user folder if it doesn't exist
    user_folder = Path(STORAGE_PATH) / current_user
    print(f"User folder path: {user_folder}")
    
    if not user_folder.exists():
        try:
            user_folder.mkdir(parents=True, exist_ok=True)
            print(f"Created user folder: {user_folder}")
        except Exception as e:
            print(f"Error creating folder {user_folder}: {e}")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Could not create user folder")

    # Create course folder
    course_folder = user_folder / (course.course_name +"_"+ course.batch_number)
    print(f"Course folder path: {course_folder}")
    
    if not course_folder.exists():
        try:
            course_folder.mkdir(parents=True, exist_ok=True)
            print(f"Created course folder: {course_folder}")
        except Exception as e:
            print(f"Error creating course folder {course_folder}: {e}")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Could not create course folder")

    return {"message": f"Course '{course.course_name}' for batch {course.batch_number} created successfully!"}



# Function to check if the string is a valid email
def is_valid_email(user: str) -> bool:
    email_regex = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    return re.match(email_regex, user) is not None


# Endpoint to get all batches (folders in storage/batches)
@app.get("/get-batches", response_model=dict)
async def get_batches():
    try:
        batches = [batch for batch in os.listdir("storage/batches") if os.path.isdir(os.path.join("storage/batches", batch))]
        return {"batches": batches}
    except Exception as e:
        return {"error": str(e)}


# Endpoint to get programs for a specific batch
@app.get("/get-programs/{batch}", response_model=dict)
async def get_programs(batch: str):
    batch_path = os.path.join("storage/batches", batch)
    if not os.path.isdir(batch_path):
        return {"error": "Batch not found"}

    try:
        programs = [program for program in os.listdir(batch_path) if os.path.isdir(os.path.join(batch_path, program))]
        return {"programs": programs}
    except Exception as e:
        return {"error": str(e)}

# Protected endpoint - only accessible with a valid token
@app.get("/protected")
async def protected_route(current_user: str = Depends(get_current_user)):
    return {"message": f"Hello {current_user}, you are authenticated!"}

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
        
        batch_number = batch_number[:2]
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

def recognize_faces(embedding, class_embeddings, threshold=0.92):
    """Compare the face embedding with class embeddings and return recognized student ID."""
    embeddings_list, names_list = class_embeddings
    for rollno, stored_embedding in zip(names_list, embeddings_list):
        distance = np.linalg.norm(embedding - stored_embedding)
        if distance < threshold:
            return rollno
    return "Unknown"

def process_face(face_img, class_embeddings):
    """Process each face image to generate embeddings and recognize students."""
    embedding = facenet.embeddings([face_img])[0]
    recognized_student = recognize_faces(embedding, class_embeddings)
    return recognized_student

async def run_in_executor(func, *args):
    """Run CPU-bound function in a separate thread."""
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, func, *args)

async def read_and_decode_file(file_data):
    # Read and decode image in a separate thread
    return await asyncio.to_thread(cv2.imdecode, np.frombuffer(file_data, np.uint8), cv2.IMREAD_COLOR)

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


# Helper function to extract student roll numbers
def get_student_roll_numbers(class_path: str):
    student_folders = os.listdir(class_path)
    return [folder for folder in student_folders if os.path.isdir(os.path.join(class_path, folder))]

# Helper function to generate Excel attendance sheet
def generate_attendance_excel(date: str, recognized_students: List[str], class_path: str, instructor_email: str,courseFolder:str):
    try:
        # File path to save or update the Excel sheet
        attendance_file_path = f"{"storage/UsersData"}/{instructor_email}/{courseFolder}/main.xlsx"

        # Ensure the folder exists
        os.makedirs("attendance_records", exist_ok=True)

        # Get the student roll numbers
        roll_numbers = get_student_roll_numbers(class_path)

        # Check if the Excel file already exists
        if os.path.exists(attendance_file_path):
            # Load existing attendance file
            df = pd.read_excel(attendance_file_path, index_col=0)
        else:
            # Create a new DataFrame with roll numbers as the index
            df = pd.DataFrame(index=roll_numbers)

        # Add the new date column if not already present
        if date not in df.columns:
            df[date] = 'A'  # Default to Absent ('A')

        # Mark recognized students as Present ('P') for the given date
        for roll_number in recognized_students:
            if roll_number in df.index:
                df.at[roll_number, date] = 'P'

        # Save the updated DataFrame back to Excel
        df.to_excel(attendance_file_path)

        return attendance_file_path

    except Exception as e:
        print(f"Error generating attendance Excel file: {e}")
        raise


@app.post("/mark-attendance")
async def mark_attendance(
    dept: str = Form(...),
    program: str = Form(...),
    sem: str = Form(...),
    class_: str = Form(...),
    batch_number: str = Form(...),
    file: UploadFile = File(...),
    token: str = Depends(oauth2_scheme)
):
    try:
        print(program)
        print(batch_number)
        print(class_)
        USERDATA = "storage/batches"

        start_time = time.time()

        # Path to the class folder
        class_path = f"{USERDATA}/{batch_number}/{program}"
        # Step 1: Read uploaded file
        file_data = await file.read()
        image = await read_and_decode_file(file_data)

        # Step 2: Resize image
        image = resize_image_aspect_ratio(image)

        # Step 3: Load class embeddings
        batch_embeddings_path = f"{"storage"}/batches/{batch_number}/{program}/batch_embeddings.pkl"

        if not os.path.exists(batch_embeddings_path):
            return {"message": "No embeddings found for this class"}

        with open(batch_embeddings_path, "rb") as f:
            class_embeddings = pickle.load(f)

        # Step 4: Extract faces from the image
        faces = await run_in_executor(extract_faces, image)
        if not faces:
            return {"message": "No faces detected in the group photo"}

        # Step 5: Generate embeddings for detected faces
        face_images = [face_img for face_img, _ in faces]
        embeddings = await asyncio.gather(
            *[run_in_executor(facenet.embeddings, [face_img]) for face_img in face_images]
        )
        embeddings = np.array([embedding[0] for embedding in embeddings])

        # Step 6: Recognize faces
        recognized_students = recognize_faces_batch(embeddings, class_embeddings)

        # Step 7: Annotate the image with recognized students
        annotated_image = image.copy()
        for (face_img, bbox), recognized_student in zip(faces, recognized_students):
            x1, y1, x2, y2 = bbox
            cv2.rectangle(annotated_image, (x1, y1), (x2, y2), (0, 255, 0), 2)
            label = recognized_student if recognized_student != "Unknown" else "Unknown"
            cv2.putText(annotated_image, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (36, 255, 12), 2)

        # Step 8: Save the annotated image
        annotated_image_filename = f"annotated_{file.filename}"
        annotated_image_path = os.path.join(attendance_static_dir, annotated_image_filename)
        compression_params = [cv2.IMWRITE_JPEG_QUALITY, 70]
        await asyncio.to_thread(cv2.imwrite, annotated_image_path, annotated_image, compression_params)


        # Get the instructor email from the JWT token
        instructor_email = get_current_user(token)

        # Step 9: Generate the Excel attendance file
        current_datetime = datetime.now()
        formatted_datetime = current_datetime.strftime("%Y-%m-%d")
        attendance_file_path = generate_attendance_excel(formatted_datetime, recognized_students, class_path, instructor_email,f"{class_}_{batch_number}-{program}")

        total_time_taken = time.time() - start_time

        return {
            "message": "Attendance marked successfully",
            "recognized_students": recognized_students,
            "annotated_image_url": f"/static/{annotated_image_filename}",
            "attendance_file_url": f"/static/attendance/{os.path.basename(attendance_file_path)}",
            "attendance_meta": formatted_datetime,
            "total_time_taken": total_time_taken
        }

    except Exception as e:
        return {"error": str(e)}