import uuid

from typing import List

from fastapi import APIRouter, Depends, status



from app.attendance.repository import AttendanceRepository

from app.attendance.schemas import AttendanceCreate, AttendanceRead, AttendanceUpdate

from app.attendance.service import AttendanceService

from config.database import AsyncSession, get_db

from config.dependences import get_current_user





from app.notification.repository import NotificationRepository

from app.notification.schemas import NotificationCreate

from app.notification.models import NotificationType

from app.websocket.manager import manager



router = APIRouter(prefix="/attendance", tags=["Attendance"])





async def get_attendance_service(session: AsyncSession = Depends(get_db)) -> AttendanceService:

    repository = AttendanceRepository(session)

    return AttendanceService(repository)





@router.post("/", response_model=AttendanceRead, status_code=status.HTTP_201_CREATED)

async def create_attendance(

        attendance_data: AttendanceCreate,

        current_user: dict = Depends(get_current_user),

        service: AttendanceService = Depends(get_attendance_service),

        session: AsyncSession = Depends(get_db),

):

    att = await service.create_attendance(attendance_data)



    

    try:

        title = "Prezență"

        status_txt = getattr(att, "status", None)

        date_txt = None

        try:

            date_txt = att.attendance_date.strftime('%d.%m.%Y')

        except Exception:

            date_txt = None



        

        subject_name = None

        try:

            subject_name = getattr(getattr(att, "subject", None), "name", None)

        except Exception:

            subject_name = None



        message = "A fost înregistrată o prezență."

        if status_txt and subject_name and date_txt:

            message = f"Status: {status_txt} la {subject_name} ({date_txt})."

        elif status_txt and date_txt:

            message = f"Status: {status_txt} ({date_txt})."



        notif_repo = NotificationRepository(session)

        notif = await notif_repo.create(

            NotificationCreate(

                title=title,

                message=message,

                notification_type=NotificationType.ATTENDANCE,

                user_id=att.student_id,

            )

        )



        await manager.send_personal_message(

            {

                "type": "attendance",

                "event": "created",

                "notification": {

                    "id": str(notif.id),

                    "title": notif.title,

                    "message": notif.message,

                    "notification_type": notif.notification_type,

                    "is_read": notif.is_read,

                    "created_at": notif.created_at.isoformat() if getattr(notif, "created_at", None) else None,

                    "user_id": str(notif.user_id),

                },

                "attendance": {

                    "id": str(att.id),

                    "attendance_date": att.attendance_date.isoformat() if getattr(att, "attendance_date", None) else None,

                    "status": getattr(att, "status", None),

                    "notes": getattr(att, "notes", None),

                    "student_id": str(att.student_id) if getattr(att, "student_id", None) else None,

                    "teacher_id": str(att.teacher_id) if getattr(att, "teacher_id", None) else None,

                    "subject_id": str(att.subject_id) if getattr(att, "subject_id", None) else None,

                },

            },

            user_id=str(att.student_id),

        )

    except Exception:

        pass



    return att





@router.get("/student/{student_id}", response_model=List[AttendanceRead])

async def get_student_attendance(

        student_id: uuid.UUID,

        current_user: dict = Depends(get_current_user),

        service: AttendanceService = Depends(get_attendance_service)

):

    return await service.get_student_attendance(student_id)





@router.get("/{attendance_id}", response_model=AttendanceRead)

async def get_attendance(

        attendance_id: uuid.UUID,

        current_user: dict = Depends(get_current_user),

        service: AttendanceService = Depends(get_attendance_service)

):

    return await service.get_attendance(attendance_id)





@router.put("/{attendance_id}", response_model=AttendanceRead)

async def update_attendance(

        attendance_id: uuid.UUID,

        attendance_data: AttendanceUpdate,

        current_user: dict = Depends(get_current_user),

        service: AttendanceService = Depends(get_attendance_service)

):

    return await service.update_attendance(attendance_id, attendance_data)





@router.delete("/{attendance_id}", status_code=status.HTTP_204_NO_CONTENT)

async def delete_attendance(

        attendance_id: uuid.UUID,

        current_user: dict = Depends(get_current_user),

        service: AttendanceService = Depends(get_attendance_service)

):

    await service.delete_attendance(attendance_id)

