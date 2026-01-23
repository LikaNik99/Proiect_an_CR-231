from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from config.database import get_db
from config.dependences import admin_required
from app.users.models.users import User
from app.users.models.students import Student
from app.users.models.teachers import Teacher
from app.school.models import School
from app.classes.models import Class

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/stats", dependencies=[Depends(admin_required)])
async def get_dashboard_stats(session: AsyncSession = Depends(get_db)):
    """Get dashboard statistics"""

    # Count schools
    schools_count = await session.scalar(select(func.count(School.id)))

    # Count classes
    classes_count = await session.scalar(select(func.count(Class.id)))

    # Count students
    students_count = await session.scalar(select(func.count(Student.user_id)))

    # Count teachers
    teachers_count = await session.scalar(select(func.count(Teacher.user_id)))

    # Count users by role
    users_by_role = await session.execute(
        select(User.role, func.count(User.id))
        .group_by(User.role)
    )
    roles_data = {role: count for role, count in users_by_role}

    # Count active vs inactive schools
    active_schools = await session.scalar(
        select(func.count(School.id)).where(School.is_active == True)
    )
    inactive_schools = schools_count - active_schools

    # Get recent users (last 30 days)
    from datetime import datetime, timedelta
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    recent_users = await session.scalar(
        select(func.count(User.id))
        .where(User.created_at >= thirty_days_ago)
    )

    # Get students per class (top 10 classes)
    students_per_class = await session.execute(
        select(Class.name, func.count(Student.user_id))
        .join(Student, Student.class_id == Class.id, isouter=True)
        .group_by(Class.id, Class.name)
        .order_by(func.count(Student.user_id).desc())
        .limit(10)
    )
    class_distribution = [
        {"class_name": name, "student_count": count}
        for name, count in students_per_class
    ]

    return {
        "total_schools": schools_count or 0,
        "total_classes": classes_count or 0,
        "total_students": students_count or 0,
        "total_teachers": teachers_count or 0,
        "users_by_role": roles_data,
        "schools_status": {
            "active": active_schools or 0,
            "inactive": inactive_schools or 0
        },
        "recent_users_30_days": recent_users or 0,
        "class_distribution": class_distribution
    }