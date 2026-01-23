import uuid
from typing import List, Optional
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload

from config.database import AsyncSession, get_db
from config.dependences import get_current_user
from app.users.models.teachers import Teacher
from app.classes.models import Class
from app.users.models.students import Student
from app.grade.models import GradeModel
from app.attendance.models import Attendance
from app.homework.models import Homework

router = APIRouter(prefix="/reports", tags=["Reports"])


@router.get("/homeroom-class")
async def get_homeroom_class_report(
    current_user: dict = Depends(get_current_user),
    session: AsyncSession = Depends(get_db)
):
    """
    Get detailed report for homeroom teacher's class
    """
    user_id = uuid.UUID(current_user["id"])

    # Get teacher and check if homeroom
    result = await session.execute(
        select(Teacher).where(Teacher.user_id == user_id)
    )
    teacher = result.scalar_one_or_none()

    if not teacher or not teacher.is_homeroom or not teacher.class_id:
        return {
            "error": "Not a homeroom teacher or no class assigned",
            "is_homeroom": teacher.is_homeroom if teacher else False
        }

    # Get class with students
    result = await session.execute(
        select(Class)
        .options(selectinload(Class.students).selectinload(Student.user))
        .where(Class.id == teacher.class_id)
    )
    school_class = result.scalar_one_or_none()

    if not school_class:
        return {"error": "Class not found"}

    # Get all student IDs
    student_ids = [s.user_id for s in school_class.students]

    # Get grades for all students
    result = await session.execute(
        select(GradeModel)
        .options(selectinload(GradeModel.subject))
        .where(GradeModel.student_id.in_(student_ids))
        .order_by(GradeModel.created_at.desc())
    )
    grades = list(result.scalars().all())

    # Get attendance for all students
    result = await session.execute(
        select(Attendance)
        .where(Attendance.student_id.in_(student_ids))
        .order_by(Attendance.attendance_date.desc())
    )
    attendance_records = list(result.scalars().all())

    # Calculate statistics per student
    students_report = []
    for student in school_class.students:
        student_grades = [g for g in grades if g.student_id == student.user_id]
        student_attendance = [a for a in attendance_records if a.student_id == student.user_id]

        avg_grade = 0.0
        if student_grades:
            avg_grade = sum(g.value for g in student_grades) / len(student_grades)

        present_count = sum(1 for a in student_attendance if str(a.status).lower() == 'present')
        total_attendance = len(student_attendance)
        attendance_rate = (present_count / total_attendance * 100) if total_attendance > 0 else 0

        students_report.append({
            "student_id": str(student.user_id),
            "username": student.user.username if student.user else "Unknown",
            "email": student.user.email if student.user else "",
            "average_grade": round(avg_grade, 2),
            "total_grades": len(student_grades),
            "attendance_rate": round(attendance_rate, 1),
            "present_count": present_count,
            "total_attendance": total_attendance,
            "recent_grades": [
                {
                    "value": g.value,
                    "subject_name": g.subject.name if g.subject else "Unknown",
                    "type": g.types.value,
                    "created_at": g.created_at.isoformat()
                }
                for g in student_grades[:5]
            ]
        })

    # Class-wide statistics
    all_grades = [g.value for g in grades]
    class_avg = sum(all_grades) / len(all_grades) if all_grades else 0

    all_present = sum(1 for a in attendance_records if str(a.status).lower() == 'present')
    all_attendance = len(attendance_records)
    class_attendance_rate = (all_present / all_attendance * 100) if all_attendance > 0 else 0

    return {
        "class_info": {
            "id": str(school_class.id),
            "name": school_class.name,
            "total_students": len(school_class.students)
        },
        "class_statistics": {
            "average_grade": round(class_avg, 2),
            "total_grades": len(grades),
            "attendance_rate": round(class_attendance_rate, 1),
            "present_count": all_present,
            "total_attendance": all_attendance
        },
        "students": students_report
    }


@router.get("/school-overview")
async def get_school_overview_report(
    current_user: dict = Depends(get_current_user),
    session: AsyncSession = Depends(get_db)
):
    """
    Get school-wide statistics (Director only)
    """
    user_id = uuid.UUID(current_user["id"])

    # Check if director
    result = await session.execute(
        select(Teacher).where(Teacher.user_id == user_id)
    )
    teacher = result.scalar_one_or_none()

    if not teacher or not teacher.is_director:
        from fastapi import HTTPException
        from fastapi import status as http_status
        raise HTTPException(
            status_code=http_status.HTTP_403_FORBIDDEN,
            detail="Only directors can access school overview"
        )

    # Get all classes with students
    result = await session.execute(
        select(Class).options(selectinload(Class.students))
    )
    classes = list(result.scalars().all())

    # Get all grades
    result = await session.execute(select(GradeModel))
    all_grades = list(result.scalars().all())

    # Get all attendance
    result = await session.execute(select(Attendance))
    all_attendance = list(result.scalars().all())

    # Get all homework
    result = await session.execute(select(Homework))
    all_homework = list(result.scalars().all())

    # Get all teachers
    result = await session.execute(select(Teacher))
    all_teachers = list(result.scalars().all())

    # Calculate per-class statistics
    classes_report = []
    for school_class in classes:
        student_ids = [s.user_id for s in school_class.students]
        class_grades = [g for g in all_grades if g.student_id in student_ids]
        class_attendance = [a for a in all_attendance if a.student_id in student_ids]

        avg_grade = 0.0
        if class_grades:
            avg_grade = sum(g.value for g in class_grades) / len(class_grades)

        present = sum(1 for a in class_attendance if str(a.status).lower() == 'present')
        total_att = len(class_attendance)
        att_rate = (present / total_att * 100) if total_att > 0 else 0

        classes_report.append({
            "class_id": str(school_class.id),
            "name": school_class.name,
            "total_students": len(school_class.students),
            "average_grade": round(avg_grade, 2),
            "total_grades": len(class_grades),
            "attendance_rate": round(att_rate, 1)
        })

    # Overall statistics
    total_students = sum(len(c.students) for c in classes)
    overall_avg = sum(g.value for g in all_grades) / len(all_grades) if all_grades else 0
    overall_present = sum(1 for a in all_attendance if str(a.status).lower() == 'present')
    overall_att_rate = (overall_present / len(all_attendance) * 100) if all_attendance else 0

    return {
        "school_statistics": {
            "total_classes": len(classes),
            "total_students": total_students,
            "total_teachers": len(all_teachers),
            "total_grades": len(all_grades),
            "average_grade": round(overall_avg, 2),
            "total_homework": len(all_homework),
            "attendance_rate": round(overall_att_rate, 1)
        },
        "classes": classes_report,
        "top_performing_classes": sorted(
            [c for c in classes_report if c["average_grade"] > 0],
            key=lambda x: x["average_grade"],
            reverse=True
        )[:5]
    }


@router.get("/teacher-performance")
async def get_teacher_performance_report(
    current_user: dict = Depends(get_current_user),
    session: AsyncSession = Depends(get_db)
):
    """
    Get teacher performance statistics (Director only)
    """
    user_id = uuid.UUID(current_user["id"])

    # Check if director
    result = await session.execute(
        select(Teacher).where(Teacher.user_id == user_id)
    )
    teacher = result.scalar_one_or_none()

    if not teacher or not teacher.is_director:
        from fastapi import HTTPException
        from fastapi import status as http_status
        raise HTTPException(
            status_code=http_status.HTTP_403_FORBIDDEN,
            detail="Only directors can access teacher performance"
        )

    # Get all teachers with their data
    result = await session.execute(
        select(Teacher)
        .options(selectinload(Teacher.user))
        .options(selectinload(Teacher.classes))
    )
    teachers = list(result.scalars().all())

    # Get all grades
    result = await session.execute(select(Grade))
    all_grades = list(result.scalars().all())

    teachers_report = []
    for t in teachers:
        # Count grades given by this teacher
        teacher_grades = [g for g in all_grades if g.teacher_id == t.user_id]

        # Count classes taught
        classes_count = len(t.classes) if t.classes else 0

        teachers_report.append({
            "teacher_id": str(t.user_id),
            "username": t.user.username if t.user else "Unknown",
            "email": t.user.email if t.user else "",
            "subject": t.subject,
            "is_homeroom": t.is_homeroom,
            "is_director": t.is_director,
            "classes_count": classes_count,
            "grades_given": len(teacher_grades),
            "last_activity": teacher_grades[0].created_at.isoformat() if teacher_grades else None
        })

    return {
        "total_teachers": len(teachers),
        "homeroom_teachers": sum(1 for t in teachers if t.is_homeroom),
        "teachers": sorted(teachers_report, key=lambda x: x["grades_given"], reverse=True)
    }
