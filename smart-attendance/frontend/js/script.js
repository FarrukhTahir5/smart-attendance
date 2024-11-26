const BASE_URL = "http://10.1.143.205:8000"; // Backend URL

// Dummy Data for Dropdowns
const data = {
  departments: {
    "Computer Science": {
      programs: {
        "BS CS": ["Fall 2020", "Spring 2021"],
        "MS CS": ["Spring 2021"],
      },
      classes: {
        "Fall 2020": [
          "CS101 - Group A - Dr. Smith",
          "CS101 - Group B - Dr. Jane",
        ],
        "Spring 2021": ["CS102 - Group A - Dr. John"],
      },
    },
    "Electrical Engineering": {
      programs: {
        "BS EE": ["Fall 2020"],
        "MS EE": ["Spring 2021"],
      },
      classes: {
        "Fall 2020": ["EE101 - Group A - Dr. Brown"],
        "Spring 2021": ["EE102 - Group A - Dr. Alice"],
      },
    },
  },
};
async function fetchWithTimeout(resource, options = {}) {
  const { timeout = 30000 } = options; // Default timeout is 30 seconds
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(resource, { ...options, signal: controller.signal });
    clearTimeout(id); // Clear timeout if request is successful
    return response;
  } catch (error) {
    clearTimeout(id); // Clear timeout on error
    throw error;
  }
}

// Helper to populate dropdowns
function populateDepartments(deptDropdownId, programDropdownId, semDropdownId, classDropdownId) {
  const deptDropdown = document.getElementById(deptDropdownId);
  const programDropdown = document.getElementById(programDropdownId);
  const semDropdown = document.getElementById(semDropdownId);
  const classDropdown = document.getElementById(classDropdownId);

  // Populate departments
  Object.keys(data.departments).forEach((dept) => {
    const option = document.createElement("option");
    option.value = dept;
    option.textContent = dept;
    deptDropdown.appendChild(option);
  });

  // Event listeners to update dependent dropdowns
  deptDropdown.addEventListener("change", () => {
    const selectedDept = deptDropdown.value;
    const programs = selectedDept ? data.departments[selectedDept].programs : {};
    populateDropdown(programDropdown, programs);
    clearDropdown(semDropdown);
    clearDropdown(classDropdown);
  });

  programDropdown.addEventListener("change", () => {
    const selectedDept = deptDropdown.value;
    const selectedProgram = programDropdown.value;
    const semesters = selectedProgram ? data.departments[selectedDept].programs[selectedProgram] : [];
    populateDropdown(semDropdown, semesters, true);
    clearDropdown(classDropdown);
  });

  semDropdown.addEventListener("change", () => {
    const selectedDept = deptDropdown.value;
    const selectedSem = semDropdown.value;
    const classes = selectedSem ? data.departments[selectedDept].classes[selectedSem] : [];
    populateDropdown(classDropdown, classes, true);
  });
}

function populateDropdown(dropdown, items, isArray = false) {
  clearDropdown(dropdown);
  if (isArray) {
    items.forEach((item) => {
      const option = document.createElement("option");
      option.value = item;
      option.textContent = item;
      dropdown.appendChild(option);
    });
  } else {
    Object.keys(items).forEach((key) => {
      const option = document.createElement("option");
      option.value = key;
      option.textContent = key;
      dropdown.appendChild(option);
    });
  }
}

function clearDropdown(dropdown) {
  dropdown.innerHTML = '<option value="">Select</option>';
}

// Populate dropdowns for each form
populateDepartments("dept", "program", "sem", "class");
populateDepartments("dept-att", "program-att", "sem-att", "class-att");
populateDepartments("dept-check", "program-check", "sem-check", "class-check");


// document.getElementById("attendance-form").addEventListener("submit", async (e) => {
//   e.preventDefault(); // Prevent page refresh

//   const formData = new FormData(e.target);

//   // Log form data for debugging
//   console.log("FormData contents:");
//   for (const [key, value] of formData.entries()) {
//     console.log(`${key}: ${value instanceof File ? value.name : value}`);
//   }

//   try {
//     document.getElementById("attendance-result").textContent = "Processing attendance. Please wait...";

//     // Create an AbortController and set a timeout
//     const controller = new AbortController();
//     const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 seconds timeout

//     const response = await fetch(`${BASE_URL}/mark-attendance`, {
//       method: "POST",
//       body: formData,
//       signal: controller.signal, // Attach the abort signal to the fetch
//     });

//     clearTimeout(timeoutId); // Clear timeout once response is received

//     if (!response.ok) {
//       const errorMessage = await response.text();
//       console.error("Server error:", errorMessage);
//       document.getElementById("attendance-result").textContent = "Failed to mark attendance: " + errorMessage;
//       return;
//     }

//     const result = await response.json();
//     console.log("Server Response:", result);

//     if (result.recognized_students) {
//       const tableBody = document.getElementById("attendance-table").querySelector("tbody");
//       tableBody.innerHTML = ""; // Clear previous rows

//       // Populate table with recognized students
//       result.recognized_students.forEach((student) => {
//         const row = document.createElement("tr");
//         row.innerHTML = `
//           <td>${student}</td>
//           <td>Present</td>
//         `;
//         tableBody.appendChild(row);
//       });

//       document.getElementById("attendance-result").textContent = "Attendance marked successfully!";
//     } else {
//       document.getElementById("attendance-result").textContent = result.message || "No recognized students.";
//     }
//   } catch (error) {
//     if (error.name === 'AbortError') {
//       console.log('Request timed out');
//       document.getElementById("attendance-result").textContent = "Attendance processing took too long and was aborted.";
//     } else {
//       console.error("Error:", error);
//       document.getElementById("attendance-result").textContent = "An error occurred while processing attendance.";
//     }
//   }
// });

// Register Form

document.getElementById("attendance-form").addEventListener("submit", async (e) => {
  e.preventDefault(); // Prevent page refresh

  const formData = new FormData(e.target);

  // Log form data for debugging
  console.log("FormData contents:");
  for (const [key, value] of formData.entries()) {
    console.log(`${key}: ${value instanceof File ? value.name : value}`);
  }

  try {
    document.getElementById("attendance-result").textContent = "Processing attendance. Please wait...";

    const response = await fetch(`${BASE_URL}/mark-attendance`, {
      method: "POST",
      body: formData,
    });

    if (!response.ok) {
      const errorMessage = await response.text();
      console.error("Server error:", errorMessage);
      document.getElementById("attendance-result").textContent = "Failed to mark attendance: " + errorMessage;
      return;
    }

    const result = await response.json();
    const taskId = result.task_id;

    console.log("Task ID:", taskId);

    // Poll the server every 2 seconds for the task status
    let statusCheckInterval = setInterval(async () => {
      const statusResponse = await fetch(`${BASE_URL}/check-task-status/${taskId}`);
      const statusData = await statusResponse.json();

      if (statusData.status === "completed") {
        clearInterval(statusCheckInterval); // Stop polling
        if (statusData.recognized_students) {
          // Process and display the recognized students
          const tableBody = document.getElementById("attendance-table").querySelector("tbody");
          tableBody.innerHTML = ""; // Clear previous rows

          statusData.recognized_students.forEach((student) => {
            const row = document.createElement("tr");
            row.innerHTML = `
              <td>${student}</td>
              <td>Present</td>
            `;
            tableBody.appendChild(row);
          });

          document.getElementById("attendance-result").textContent = "Attendance marked successfully!";
        } else {
          document.getElementById("attendance-result").textContent = statusData.message || "No recognized students.";
        }
      } else if (statusData.status === "not found") {
        clearInterval(statusCheckInterval); // Stop polling if task is not found
        document.getElementById("attendance-result").textContent = "Error: Task not found.";
      }
    }, 2000); // Poll every 2 seconds

  } catch (error) {
    console.error("Error:", error);
    document.getElementById("attendance-result").textContent = "An error occurred while processing attendance.";
  }
});


document.getElementById("register-form").addEventListener("submit", async (e) => {
  e.preventDefault();

  const formData = new FormData(e.target);
  document.getElementById("register-result").textContent = "Registering student. Please wait...";

  try {
    const response = await fetch(`${BASE_URL}/register`, {
      method: "POST",
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }

    const result = await response.json();
    document.getElementById("register-result").textContent = result.message || "Student registered successfully.";
  } catch (error) {
    console.error("Error:", error);
    document.getElementById("register-result").textContent =
      "An error occurred while registering the student.";
  }
});

// Check Attendance Form Submission
document.getElementById("check-attendance-form").addEventListener("submit", async (e) => {
  e.preventDefault();

  const formData = new FormData(e.target);
  const params = new URLSearchParams();
  formData.forEach((value, key) => params.append(key, value));

  document.getElementById("check-result").textContent = "Fetching attendance. Please wait...";

  try {
    const response = await fetch(`${BASE_URL}/attendance?${params.toString()}`);
    const result = await response.json();

    if (result.present) {
      const tableBody = document.getElementById("attendance-table").querySelector("tbody");
      tableBody.innerHTML = ""; // Clear previous rows
      result.present.forEach((student) => {
        const row = document.createElement("tr");
        row.innerHTML = `
          <td>${student}</td>
          <td>Present</td>
        `;
        tableBody.appendChild(row);
      });
      document.getElementById("check-result").textContent = "Attendance records fetched successfully!";
    } else {
      document.getElementById("check-result").textContent =
        result.message || "No attendance records found.";
    }
  } catch (error) {
    console.error("Error:", error);
    document.getElementById("check-result").textContent =
      "An error occurred while fetching attendance records.";
  }
});
