from fastapi import FastAPI

from fastapi.responses import HTMLResponse

from fastapi.staticfiles import StaticFiles

import os



from app.attendance.routes import router as attendance_router

from app.auth.routes import router as auth_router

from app.classes.routes import router as classes_router

from app.classes.schemas import ClassBase

from app.dashboard.routes import router as dashboard_router

from app.grade.routes import router as grade_router

from app.homework.routes import router as homework_router

from app.material.routes import router as material_router

from app.notification.routes import router as notification_router

from app.password.routes import router as password_router

from app.reports.routes import router as reports_router

from app.schedule.routes import router as schedule_router

from app.school.routes import router as school_router

from app.subject.routes import router as subject_router

from app.users.routes.student import router as student_router

from app.users.routes.teacher import router as teacher_router

from app.users.routes.user import router as user_router

from app.users.schemas import TeacherRead, StudentRead

from app.websocket.routes import router as websocket_router

from middleware import setup_cors



app = FastAPI(

    title="School App API",

    description="Backend API for School Management Application",

    version="1.0.0"

)





UPLOADS_DIR = os.environ.get("UPLOADS_DIR", "uploads")

if not os.path.exists(UPLOADS_DIR):

    os.makedirs(UPLOADS_DIR, exist_ok=True)





app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")



ClassBase.model_rebuild(_types_namespace={"TeacherRead": TeacherRead, "StudentRead": StudentRead})



setup_cors(app)





app.include_router(auth_router)

app.include_router(school_router)

app.include_router(teacher_router)

app.include_router(user_router)

app.include_router(student_router)

app.include_router(classes_router)

app.include_router(password_router)

app.include_router(dashboard_router)

app.include_router(grade_router)

app.include_router(subject_router)

app.include_router(schedule_router)

app.include_router(homework_router)

app.include_router(attendance_router)

app.include_router(notification_router)

app.include_router(material_router)

app.include_router(reports_router)





app.include_router(websocket_router)





@app.get("/", response_class=HTMLResponse)

def start_page():

    return """
       <!DOCTYPE html>
       <html>
           <head>
               <title>Home</title>
           </head>
           <body style="text-align:center; margin-top:50px;">
               <h1>Welcome</h1>
               <button onclick="window.location.href='/docs'">
                   Go to API Docs
               </button>
           </body>
       </html>
       """

