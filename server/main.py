import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "api:app",
        host="172.18.22.164",
        port=8000,
        reload=True
    )
