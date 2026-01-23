import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.ext.asyncio import create_async_engine

from alembic import context

from config.database import Base, DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS
from app.users.models import User, Student, Teacher
from app.grade.models import GradeModel, GradeTypes
from app.school.models import School
from app.classes.models import Class
from app.subject.models import Subject
from app.schedule.models import Schedule, DayOfWeek
from app.homework.models import Homework, HomeworkStatus
from app.attendance.models import Attendance, AttendanceStatus
from app.notification.models import Notification, NotificationType
from app.message.models import Message
from app.material.models import Material

config = context.config
section = config.config_ini_section
config.set_section_option(section, "DB_HOST", str(DB_HOST))
config.set_section_option(section, "DB_PORT", str(DB_PORT))
config.set_section_option(section, "DB_NAME", str(DB_NAME))
config.set_section_option(section, "DB_USER", str(DB_USER))
config.set_section_option(section, "DB_PASS", str(DB_PASS))

# Logging
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline():
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    connectable = create_async_engine(
        config.get_main_option("sqlalchemy.url"),
        poolclass=pool.NullPool,
    )

    async def do_run_migrations(connection):
        await connection.run_sync(
            lambda sync_conn: context.configure(
                connection=sync_conn,
                target_metadata=target_metadata
            )
        )
        await connection.run_sync(lambda sync_conn: context.run_migrations())

    async def async_main():
        async with connectable.begin() as conn:
            await do_run_migrations(conn)

    asyncio.run(async_main())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
