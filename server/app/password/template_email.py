def build_reset_password_html(code: int, email: str):
    return f"""
    <html>
    <head>
      <style>
        body {{
          font-family: Arial, sans-serif;
          background-color: #f4f4f4;
          margin: 0;
          padding: 0;
        }}
        .container {{
          max-width: 600px;
          margin: 30px auto;
          background-color: #ffffff;
          border-radius: 10px;
          box-shadow: 0 4px 10px rgba(0,0,0,0.1);
          padding: 20px;
        }}
        h2 {{
          color: #333333;
        }}
        p {{
          font-size: 16px;
          color: #555555;
        }}
        .code {{
          display: inline-block;
          background-color: #e0f7fa;
          color: #00796b;
          font-size: 24px;
          font-weight: bold;
          padding: 10px 20px;
          border-radius: 5px;
          letter-spacing: 4px;
          margin: 20px 0;
        }}
        .footer {{
          font-size: 12px;
          color: #999999;
          margin-top: 30px;
          text-align: center;
        }}
        a.button {{
          display: inline-block;
          padding: 12px 25px;
          margin-top: 20px;
          background-color: #00796b;
          color: white !important;
          text-decoration: none;
          border-radius: 5px;
        }}
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Hello, {email}!</h2>
        <p>You requested to reset your password. Use the following code to reset it:</p>
        <div class="code">{code}</div>
        <p>If you did not request this, please ignore this email.</p>
        <div class="footer">
          &copy; 2025 SchoolAPP. All rights reserved.
        </div>
      </div>
    </body>
    </html>
    """
