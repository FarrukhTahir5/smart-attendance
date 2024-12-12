# Attendance Management System API Reference

## Authentication Endpoints

### 1. Login Endpoint
- **URL**: `/login`
- **Method**: POST
- **Description**: Authenticates user and returns a JWT access token
- **Input**: 
  - `username` (email)
  - `password`
- **Output**:
  ```json
  {
    "access_token": "jwt_token_string",
    "token_type": "bearer"
  }
  ```
- **Error Responses**:
  - 401 Unauthorized: Invalid email or password

### 2. Protected Route
- **URL**: `/protected`
- **Method**: GET
- **Description**: A sample protected route that validates the JWT token
- **Authentication**: Requires valid JWT token
- **Output**:
  ```json
  {
    "message": "Hello user@email.com, you are authenticated!"
  }
  ```

## Course and File Management Endpoints

### 3. Get Courses
- **URL**: `/courses`
- **Method**: GET
- **Description**: Retrieves list of courses for the current authenticated user
- **Authentication**: Requires valid JWT token
- **Output**: 
  ```json
  [
    {
      "className": "Course Name",
      "department": "Department",
      "program": "Program",
      "batch": "Batch",
      "semester": "Semester"
    }
  ]
  ```

### 4. Get Excel Files
- **URL**: `/files/{courseFolder}`
- **Method**: GET
- **Description**: Lists Excel files for a specific course folder
- **Authentication**: Requires valid JWT token
- **Input Parameters**:
  - `courseFolder`: Specific course folder name
- **Output**:
  ```json
  [
    {
      "file_name": "example.xlsx",
      "file_path": "relative/path/to/file.xlsx"
    }
  ]
  ```

### 5. Add Course
- **URL**: `/add-course/`
- **Method**: POST
- **Description**: Creates a new course folder for the authenticated user
- **Authentication**: Requires valid JWT token
- **Input**:
  ```json
  {
    "course_name": "Course Name",
    "batch_number": "Batch"
  }
  ```
- **Output**:
  ```json
  {
    "message": "Course 'CourseName' for batch BatchNumber created successfully!"
  }
  ```

## Batch and Program Management Endpoints

### 6. Get Batches
- **URL**: `/get-batches`
- **Method**: GET
- **Description**: Retrieves list of all available batches
- **Output**:
  ```json
  {
    "batches": ["Batch1", "Batch2", ...]
  }
  ```

### 7. Get Programs for Batch
- **URL**: `/get-programs/{batch}`
- **Method**: GET
- **Description**: Retrieves programs for a specific batch
- **Input Parameters**:
  - `batch`: Batch name
- **Output**:
  ```json
  {
    "programs": ["Program1", "Program2", ...]
  }
  ```

## Student Management Endpoints

### 8. Upload Student Image
- **URL**: `/upload-student-image`
- **Method**: POST
- **Description**: Uploads a single student image
- **Input (Form Data)**:
  - `name`: Student Name
  - `rollno`: Student Roll Number
  - `program`: Study Program
  - `batch_number`: Batch
  - `file`: Image File
- **Output**:
  ```json
  {
    "message": "file uploaded"
  }
  ```

### 9. Register Student
- **URL**: `/register`
- **Method**: POST
- **Description**: Registers a student with multiple images for face recognition
- **Input (Form Data)**:
  - `name`: Student Name
  - `rollno`: Student Roll Number
  - `batch_number`: Batch
  - `program`: Study Program
  - `files`: Multiple Image Files
- **Output**:
  ```json
  {
    "message": "Student Name (Roll No: RollNumber) registered successfully in Batch BatchNumber for Program."
  }
  ```

## Attendance Endpoints

### 10. Mark Attendance
- **URL**: `/mark-attendance`
- **Method**: POST
- **Description**: Marks attendance for a class using group photo and face recognition
- **Authentication**: Requires valid JWT token
- **Input (Form Data)**:
  - `dept`: Department
  - `program`: Study Program
  - `sem`: Semester
  - `class_`: Class Name
  - `batch_number`: Batch
  - `file`: Group Photo File
- **Output**:
  ```json
  {
    "message": "Attendance marked successfully",
    "recognized_students": ["RollNumber1", "RollNumber2"],
    "annotated_image_url": "/static/annotated_filename.jpg",
    "attendance_file_url": "/static/attendance/attendance_filename.xlsx",
    "attendance_meta": "YYYY-MM-DD",
    "total_time_taken": 5.23
  }
  ```

### 11. Get File Download Link
- **URL**: `/get_file_download_link`
- **Method**: POST
- **Description**: Generates a download link for a specific file
- **Input**:
  ```json
  {
    "file_path": "relative/path/to/file"
  }
  ```
- **Output**:
  ```json
  {
    "file_url": "/static/filename"
  }
  ```

## Authentication Notes
- All protected endpoints require a valid JWT token obtained from the `/login` endpoint
- Include the token in the Authorization header as: `Authorization: Bearer <token>`

## Error Handling
- 401: Unauthorized (Invalid credentials)
- 403: Forbidden (Invalid user)
- 404: Resource Not Found
- 500: Server Error

