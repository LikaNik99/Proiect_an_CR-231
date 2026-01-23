#!/bin/bash
set -e

echo " Pornire container server..."

# SeteazДѓ DATABASE_URL pentru iniИ›ializare (suprascrie dacДѓ nu e setat Г®n env)
if [ -z "$DATABASE_URL" ]; then
    export DATABASE_URL=sqlite:///./data/schedule.db
    # CreeazДѓ directorul pentru baza de date SQLite dacДѓ nu existДѓ
    mkdir -p /app/data
    echo " Director baza de date SQLite: /app/data"
else
    echo " Folosind baza de date configuratДѓ prin DATABASE_URL"
fi

echo " DATABASE_URL: $DATABASE_URL"

# VerificДѓ tipul de bazДѓ de date
if [[ "$DATABASE_URL" == postgresql* ]]; then
    echo " DetectatДѓ bazДѓ de date PostgreSQL"
    echo " AИ™teptДѓ conexiunea la PostgreSQL..."
    
    # FoloseИ™te Python pentru a verifica conexiunea (mai robust decГўt sed)
    MAX_ATTEMPTS=60
    ATTEMPT=0
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        # VerificДѓ conexiunea folosind Python И™i SQLAlchemy
        if python -c "
import os
import sys
from sqlalchemy import create_engine, text
try:
    engine = create_engine(os.getenv('DATABASE_URL'))
    with engine.connect() as conn:
        conn.execute(text('SELECT 1'))
    sys.exit(0)
except Exception:
    sys.exit(1)
" 2>/dev/null; then
            echo "вњ“ PostgreSQL este gata!"
            break
        fi
        ATTEMPT=$((ATTEMPT + 1))
        if [ $((ATTEMPT % 5)) -eq 0 ]; then
            echo " AИ™tept PostgreSQL... ($ATTEMPT/$MAX_ATTEMPTS)"
        fi
        sleep 1
    done
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo " Eroare: PostgreSQL nu este disponibil dupДѓ $MAX_ATTEMPTS secunde"
        exit 1
    fi
else
    echo " DetectatДѓ bazДѓ de date SQLite"
    # IniИ›ializeazДѓ baza de date SQLite dacДѓ nu existДѓ
    if [ ! -f "/app/data/schedule.db" ]; then
        echo " IniИ›ializare baza de date SQLite..."
        cd /app
        python init_db.py
        echo "вњ“ Baza de date SQLite iniИ›ializatДѓ!"
    else
        echo "вњ“ Baza de date SQLite deja existДѓ, se continuДѓ..."
    fi
fi

# RuleazДѓ migrДѓrile Alembic pentru a crea/actualiza schema
echo " Rulare migrДѓri Alembic..."
cd /app
python -m alembic upgrade head || echo "  AtenИ›ie: MigrДѓrile Alembic au eИ™uat sau nu existДѓ migrДѓri"

echo " Pornire server FastAPI..."
# RuleazДѓ comanda primitДѓ (uvicorn)
exec "$@"
