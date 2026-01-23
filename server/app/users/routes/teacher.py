import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, status, HTTPException
from fastapi.responses import JSONResponse
from sqlalchemy import select
import sqlalchemy as sa
from sqlalchemy.orm import selectinload

from app.classes.models import Class
from app.schedule.models import Schedule
from app.users.models import Teacher
from app.users.models.students import Student
from app.users.models.teacher_subjects import TeacherClassSubject, TeacherSubject
from app.users.repositories.teacher import TeacherRepository
from app.users.repositories.user import UserRepository
from app.users.schemas.teacher import TeacherRead, TeacherCreate, TeacherUpdate
from app.users.services.teacher import TeacherService
from config.database import AsyncSession, get_db
from config.dependences import admin_required, get_current_user, director_required

router = APIRouter(prefix="/teachers", tags=["Teachers"])


async def get_teacher_service(session: AsyncSession = Depends(get_db)) -> TeacherService:
    teacher_repository = TeacherRepository(session)
    user_repository = UserRepository(session)
    return TeacherService(repository=teacher_repository, user_repository=user_repository)


async def admin_or_director_required(current_user: dict = Depends(get_current_user)):
    """Allow both admin and director to access"""
    if current_user["role"] == "admin":
        return current_user

    # Check if teacher is director
    try:
        return await director_required(current_user)
    except HTTPException:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admin or director can access this resource"
        )


@router.get("/", response_model=List[TeacherRead], dependencies=[Depends(admin_or_director_required)])
async def get_all_teachers(skip: int = 0, limit: int = 100, q: Optional[str] = None, service: TeacherService = Depends(get_teacher_service)):
    return await service.get_all_teachers(skip=skip, limit=limit, q=q)


@router.get("/me", response_model=TeacherRead)
async def get_current_teacher(
        current_user: dict = Depends(get_current_user),
        service: TeacherService = Depends(get_teacher_service),
        session: AsyncSession = Depends(get_db),
):
    try:
        user_uuid = uuid.UUID(current_user["id"])
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID in token",
        )

    teacher = await service.repository.get_by_user_id(user_uuid)

    if not teacher:
        new_teacher = Teacher(
            user_id=user_uuid,
        )
        session.add(new_teacher)
        await session.commit()
        await session.refresh(new_teacher)
        teacher = await service.repository.get_by_user_id(user_uuid)

    await session.refresh(teacher, attribute_names=["user"])

    # SPECIAL CASE: If director, load ALL classes from their school
    if teacher.is_director:
        # Get director's school_id from their user
        school_id = teacher.user.school_id if teacher.user else None

        if school_id:
            # Load all classes from the school with students and teachers
            classes_query = select(Class).where(Class.school_id == school_id).options(
                selectinload(Class.students).selectinload(Student.user),
                selectinload(Class.teacher).selectinload(Teacher.user)  # Homeroom teacher with user
            )
            result = await session.execute(classes_query)
            classes = list(result.scalars().all())

            # For director, we still need subjects they can view (all subjects from school)
            # Get all subjects from schedules in this school
            all_schedules_query = select(Schedule).where(
                Schedule.class_id.in_([c.id for c in classes])
            ).options(selectinload(Schedule.subject))

            all_schedules_result = await session.execute(all_schedules_query)
            all_schedules = list(all_schedules_result.scalars().all())

            subjects_map = {}
            for sch in all_schedules:
                subj = getattr(sch, 'subject', None)
                if subj is None:
                    continue
                subjects_map[str(subj.id)] = {'id': str(subj.id), 'name': subj.name}

            # Build serialized classes with all subjects
            serialized_classes = []
            for c in classes:
                # Get homeroom teacher info
                homeroom_teacher = getattr(c, 'teacher', None)
                homeroom_teacher_id = str(homeroom_teacher.user_id) if homeroom_teacher else None
                homeroom_teacher_name = homeroom_teacher.user.username if (homeroom_teacher and homeroom_teacher.user) else None

                # Get all subjects for this class from schedules
                class_subjects_map = {}
                for sch in all_schedules:
                    if str(sch.class_id) == str(c.id):
                        subj = getattr(sch, 'subject', None)
                        if subj:
                            class_subjects_map[str(subj.id)] = {'id': str(subj.id), 'name': subj.name}

                serialized = {
                    'id': str(c.id),
                    'name': c.name,
                    'school_id': str(c.school_id),
                    'teacher_id': homeroom_teacher_id,
                    'homeroom_teacher': homeroom_teacher_name,
                    'subjects': list(class_subjects_map.values()),
                    'students': [
                        {
                            'user_id': str(s.user_id),
                            'class_id': str(s.class_id),
                            'user': {
                                'username': s.user.username if s.user else None,
                                'email': s.user.email if s.user else None,
                            } if s.user else None
                        } for s in c.students
                    ]
                }
                serialized_classes.append(serialized)

            return {
                'user_id': str(teacher.user_id),
                'user': {
                    'id': str(teacher.user.id),
                    'username': teacher.user.username,
                    'email': teacher.user.email,
                    'role': teacher.user.role,
                    'is_activated': teacher.user.is_activated,
                    'avatar_url': teacher.user.avatar_url,
                    'created_at': teacher.user.created_at.isoformat() if teacher.user.created_at else None,
                    'updated_at': teacher.user.updated_at.isoformat() if teacher.user.updated_at else None,
                },
                'subject': teacher.subject,
                'is_homeroom': teacher.is_homeroom,
                'is_director': teacher.is_director,
                'created_at': teacher.created_at.isoformat() if teacher.created_at else None,
                'updated_at': teacher.updated_at.isoformat() if teacher.updated_at else None,
                'classes': serialized_classes,
            }

    # NORMAL CASE: Regular teacher or homeroom teacher
    # Prefer explicit teacher<->class<->subject assignments
    tcs_query = select(TeacherClassSubject).where(TeacherClassSubject.teacher_id == user_uuid).options(
        selectinload(TeacherClassSubject.subject)
    )
    tcs_res = await session.execute(tcs_query)
    teacher_class_subjects = list(tcs_res.scalars().all())

    # Classes the teacher teaches (distinct from assignments). Fallback to homeroom classes.
    if teacher_class_subjects:
        class_ids = sorted({tcs.class_id for tcs in teacher_class_subjects})
        classes_query = select(Class).where(Class.id.in_(class_ids)).options(
            selectinload(Class.students).selectinload(Student.user)
        )
    else:
        classes_query = select(Class).where(Class.teacher_id == user_uuid).options(
            selectinload(Class.students).selectinload(Student.user)
        )

    result = await session.execute(classes_query)
    classes = list(result.scalars().all())

    # Prefer explicit teacher<->class<->subject assignments for subjects
    subjects_map = {}
    for tcs in teacher_class_subjects:
        subj = getattr(tcs, 'subject', None)
        if subj is None:
            continue
        subjects_map[str(subj.id)] = {'id': str(subj.id), 'name': subj.name}

    # Fallback: if no explicit table rows exist yet, derive from schedules
    teacher_schedules = []
    if not subjects_map:
        schedules_query = select(Schedule).where(Schedule.teacher_id == user_uuid).options(
            selectinload(Schedule.subject)
        )
        schedules_result = await session.execute(schedules_query)
        teacher_schedules = list(schedules_result.scalars().all())
        for sch in teacher_schedules:
            subj = getattr(sch, 'subject', None)
            if subj is None:
                continue
            subjects_map[str(subj.id)] = {'id': str(subj.id), 'name': subj.name}

    # Serialize Class ORM objects to plain dicts so JSON can be returned
    serialized_classes = []
    for c in classes:
        class_subjects_map = {}

        # from explicit assignment table
        for tcs in teacher_class_subjects:
            if str(getattr(tcs, 'class_id', '')) != str(getattr(c, 'id', '')):
                continue
            subj = getattr(tcs, 'subject', None)
            if subj is None:
                continue
            class_subjects_map[str(subj.id)] = {'id': str(subj.id), 'name': subj.name}

        # fallback from schedule if still empty
        if not class_subjects_map and teacher_schedules:
            for sch in teacher_schedules:
                if str(getattr(sch, 'class_id', '')) != str(getattr(c, 'id', '')):
                    continue
                subj = getattr(sch, 'subject', None)
                if subj is None:
                    continue
                class_subjects_map[str(subj.id)] = {'id': str(subj.id), 'name': subj.name}

        serialized = {
            'id': str(c.id) if getattr(c, 'id', None) else None,
            'name': c.name,
            'school_id': str(c.school_id) if getattr(c, 'school_id', None) else None,
            'created_at': c.created_at.isoformat() if getattr(c, 'created_at', None) else None,
            'updated_at': c.updated_at.isoformat() if getattr(c, 'updated_at', None) else None,
            'teacher_id': str(c.teacher_id) if getattr(c, 'teacher_id', None) else None,
            'students': [],
            # NEW: subjects this teacher teaches in this class
            'subjects': list(class_subjects_map.values()),
        }
        for s in getattr(c, 'students', []):
            # each student has a user attribute loaded
            user_obj = getattr(s, 'user', None)
            serialized_user_obj = {
                'id': str(s.user_id) if getattr(s, 'user_id', None) else None,
                'username': getattr(user_obj, 'username', '') if user_obj else '',
                'name': getattr(user_obj, 'username', '') if user_obj else '',
                'email': getattr(user_obj, 'email', '') if user_obj else '',
                'class_id': str(c.id) if getattr(c, 'id', None) else None,
                'school_id': str(c.school_id) if getattr(c, 'school_id', None) else None,
            }

            serialized_student = {
                'user_id': str(s.user_id) if getattr(s, 'user_id', None) else None,
                'class_id': str(c.id) if getattr(c, 'id', None) else None,
                'parent_id': str(getattr(s, 'parent_id', '')) if getattr(s, 'parent_id', None) else None,
                # provide nested user object to match client expectations
                'user': serialized_user_obj,
                # backward-compatible top-level fields
                'username': serialized_user_obj.get('username'),
                'email': serialized_user_obj.get('email'),
            }
            serialized['students'].append(serialized_student)
        serialized_classes.append(serialized)

    # Serialize teacher.user to plain dict instead of passing ORM object
    serialized_user = {}
    if getattr(teacher, 'user', None):
        u = teacher.user
        serialized_user = {
            'id': str(getattr(u, 'id', None)) if getattr(u, 'id', None) else None,
            'username': getattr(u, 'username', '') or '',
            'email': getattr(u, 'email', '') or '',
            'avatar_url': getattr(u, 'avatar_url', None),
            'school_id': str(getattr(u, 'school_id', None)) if getattr(u, 'school_id', None) else None,
        }

    # Debug log to help client debugging - shows what server will return
    try:
        print('DEBUG teacher.serialized_user=', serialized_user)
        print('DEBUG teacher.serialized_classes_count=', len(serialized_classes))
        if len(serialized_classes) > 0:
            print('DEBUG first class students count=', len(serialized_classes[0].get('students', [])))
    except Exception:
        pass

    # Build explicit payload with strings for UUIDs and ISO datetimes
    teacher_payload = {
        'user_id': str(teacher.user_id) if getattr(teacher, 'user_id', None) else None,
        'subject': teacher.subject,
        'is_homeroom': teacher.is_homeroom,
        'is_director': teacher.is_director,
        'class_id': str(teacher.class_id) if getattr(teacher, 'class_id', None) else None,
        'school_id': str(teacher.user.school_id) if getattr(teacher, 'user', None) and getattr(teacher.user, 'school_id', None) else None,
        'user': serialized_user,
        'classes': serialized_classes,
        # NEW: distinct subjects this teacher teaches (from schedules)
        'subjects': list(subjects_map.values()),
        'created_at': teacher.created_at.isoformat() if getattr(teacher, 'created_at', None) else None,
        'updated_at': teacher.updated_at.isoformat() if getattr(teacher, 'updated_at', None) else None,
    }

    return JSONResponse(content=teacher_payload)


@router.get("/me/classes/{class_id}/subjects")
async def get_my_subjects_for_class(
    class_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """Return subjects taught by the current teacher in the given class.

    Preferred source: teacher_class_subjects.
    Fallback: schedules (teacher_id + class_id).

    Response: [{"id": "<uuid>", "name": "<subject>"}, ...]
    """

    try:
        teacher_id = uuid.UUID(current_user["id"])
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user ID in token")

    # Preferred: explicit assignment table
    tcs_res = await session.execute(
        select(TeacherClassSubject)
        .where(
            TeacherClassSubject.teacher_id == teacher_id,
            TeacherClassSubject.class_id == class_id,
        )
        .options(selectinload(TeacherClassSubject.subject))
    )
    tcs_rows = list(tcs_res.scalars().all())

    subjects_map: dict[str, dict] = {}
    for row in tcs_rows:
        subj = getattr(row, "subject", None)
        if subj is None:
            continue
        subjects_map[str(subj.id)] = {"id": str(subj.id), "name": subj.name}

    # Fallback: schedules
    if not subjects_map:
        sch_res = await session.execute(
            select(Schedule)
            .where(
                Schedule.teacher_id == teacher_id,
                Schedule.class_id == class_id,
            )
            .options(selectinload(Schedule.subject))
        )
        sch_rows = list(sch_res.scalars().all())
        for sch in sch_rows:
            subj = getattr(sch, "subject", None)
            if subj is None:
                continue
            subjects_map[str(subj.id)] = {"id": str(subj.id), "name": subj.name}

    return list(subjects_map.values())


@router.get("/me/teaching-classes")
async def get_my_teaching_classes(
    current_user: dict = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """Return classes where current teacher teaches, with subjects per class.

    Source of truth: teacher_class_subjects.

    Response: [{id,name,school_id,teacher_id,subjects:[{id,name}],students:[...]}]

    Note: this intentionally does NOT include homeroom classes unless they are also present in
    teacher_class_subjects.
    """
    try:
        teacher_id = uuid.UUID(current_user["id"])
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user ID in token")

    # Load teacher_class_subject rows + subjects
    tcs_res = await session.execute(
        select(TeacherClassSubject)
        .where(TeacherClassSubject.teacher_id == teacher_id)
        .options(selectinload(TeacherClassSubject.subject))
    )
    tcs_rows = list(tcs_res.scalars().all())

    if not tcs_rows:
        return []

    class_ids = sorted({row.class_id for row in tcs_rows})

    classes_res = await session.execute(
        select(Class)
        .where(Class.id.in_(class_ids))
        .options(selectinload(Class.students).selectinload(Student.user))
    )
    classes = list(classes_res.scalars().all())

    # Build subjects per class
    subjects_by_class: dict[str, dict[str, dict]] = {}
    for row in tcs_rows:
        cid = str(row.class_id)
        subj = getattr(row, "subject", None)
        if subj is None:
            continue
        subjects_by_class.setdefault(cid, {})[str(subj.id)] = {"id": str(subj.id), "name": subj.name}

    serialized_classes = []
    for c in classes:
        cid = str(getattr(c, 'id', ''))
        class_subjects = list(subjects_by_class.get(cid, {}).values())

        serialized = {
            'id': str(c.id) if getattr(c, 'id', None) else None,
            'name': c.name,
            'school_id': str(c.school_id) if getattr(c, 'school_id', None) else None,
            'created_at': c.created_at.isoformat() if getattr(c, 'created_at', None) else None,
            'updated_at': c.updated_at.isoformat() if getattr(c, 'updated_at', None) else None,
            'teacher_id': str(c.teacher_id) if getattr(c, 'teacher_id', None) else None,
            'students': [],
            'subjects': class_subjects,
        }

        for s in getattr(c, 'students', []):
            user_obj = getattr(s, 'user', None)
            serialized_user_obj = {
                'id': str(s.user_id) if getattr(s, 'user_id', None) else None,
                'username': getattr(user_obj, 'username', '') if user_obj else '',
                'name': getattr(user_obj, 'username', '') if user_obj else '',
                'email': getattr(user_obj, 'email', '') if user_obj else '',
                'class_id': str(c.id) if getattr(c, 'id', None) else None,
                'school_id': str(c.school_id) if getattr(c, 'school_id', None) else None,
            }
            serialized_student = {
                'user_id': str(s.user_id) if getattr(s, 'user_id', None) else None,
                'class_id': str(c.id) if getattr(c, 'id', None) else None,
                'parent_id': str(getattr(s, 'parent_id', '')) if getattr(s, 'parent_id', None) else None,
                'user': serialized_user_obj,
                'username': serialized_user_obj.get('username'),
                'email': serialized_user_obj.get('email'),
            }
            serialized['students'].append(serialized_student)

        serialized_classes.append(serialized)

    return serialized_classes


@router.get("/{teacher_id}", response_model=TeacherRead)
async def get_teacher_by_id(
        teacher_id: uuid.UUID, service: TeacherService = Depends(get_teacher_service)
):
    return await service.get_teacher_by_id(teacher_id)


@router.get("/{teacher_id}/students", response_model=List[dict])
async def get_teacher_students(teacher_id: uuid.UUID, service: TeacherService = Depends(get_teacher_service)):
    return await service.get_students_for_teacher(teacher_id)


@router.get("/{teacher_id}/assignments", dependencies=[Depends(admin_required)])
async def get_teacher_assignments(
    teacher_id: uuid.UUID,
    session: AsyncSession = Depends(get_db),
):
    ts_res = await session.execute(
        select(TeacherSubject).where(TeacherSubject.teacher_id == teacher_id).options(selectinload(TeacherSubject.subject))
    )
    tcs_res = await session.execute(
        select(TeacherClassSubject)
        .where(TeacherClassSubject.teacher_id == teacher_id)
        .options(selectinload(TeacherClassSubject.subject), selectinload(TeacherClassSubject.class_))
    )
    ts = list(ts_res.scalars().all())
    tcs = list(tcs_res.scalars().all())

    return {
        "teacher_id": str(teacher_id),
        "subjects": [
            {"id": str(x.subject.id), "name": x.subject.name}
            for x in ts
            if getattr(x, "subject", None) is not None
        ],
        "class_subjects": [
            {
                "id": str(x.id),
                "class_id": str(x.class_id),
                "class_name": getattr(getattr(x, "class_", None), "name", None),
                "subject_id": str(x.subject_id),
                "subject_name": getattr(getattr(x, "subject", None), "name", None),
            }
            for x in tcs
        ],
    }


@router.post("/", response_model=TeacherRead, status_code=status.HTTP_201_CREATED,
             dependencies=[Depends(admin_required)])
async def create_teacher(
        teacher_data: TeacherCreate, service: TeacherService = Depends(get_teacher_service)
):
    return await service.create_teacher(teacher_data)


@router.put("/{teacher_id}", response_model=TeacherRead, dependencies=[Depends(admin_required)])
async def update_teacher(
        teacher_id: uuid.UUID,
        teacher_data: TeacherUpdate,
        service: TeacherService = Depends(get_teacher_service),
):
    return await service.update_teacher(teacher_id, teacher_data)


@router.delete("/{teacher_id}", status_code=status.HTTP_200_OK, dependencies=[Depends(admin_required)])
async def delete_teacher(
        teacher_id: uuid.UUID, service: TeacherService = Depends(get_teacher_service)
):
    await service.delete_teacher(teacher_id)
    return {"message": f"Teacher with id {teacher_id} deleted successfully."}


@router.post("/{teacher_id}/subjects", dependencies=[Depends(admin_required)])
async def set_teacher_subjects(
    teacher_id: uuid.UUID,
    subject_ids: List[uuid.UUID],
    session: AsyncSession = Depends(get_db),
):
    # replace set
    await session.execute(
        sa.delete(TeacherSubject).where(TeacherSubject.teacher_id == teacher_id)
    )
    for sid in subject_ids:
        session.add(TeacherSubject(teacher_id=teacher_id, subject_id=sid))
    await session.commit()
    return {"status": "ok"}


@router.post("/{teacher_id}/class-subject", dependencies=[Depends(admin_required)])
async def add_teacher_class_subject(
    teacher_id: uuid.UUID,
    payload: dict,
    session: AsyncSession = Depends(get_db),
):
    class_id = payload.get("class_id")
    subject_id = payload.get("subject_id")
    if not class_id or not subject_id:
        raise HTTPException(status_code=400, detail="class_id and subject_id are required")

    try:
        class_uuid = uuid.UUID(str(class_id))
        subj_uuid = uuid.UUID(str(subject_id))
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid UUID")

    existing = await session.execute(
        select(TeacherClassSubject).where(
            TeacherClassSubject.teacher_id == teacher_id,
            TeacherClassSubject.class_id == class_uuid,
            TeacherClassSubject.subject_id == subj_uuid,
        )
    )
    if existing.scalars().first() is not None:
        return {"status": "exists"}

    session.add(
        TeacherClassSubject(
            teacher_id=teacher_id,
            class_id=class_uuid,
            subject_id=subj_uuid,
        )
    )
    await session.commit()
    return {"status": "ok"}
