import requests

BASE_URL = "http://47.113.120.111:8000/api/v1"

# 测试用户注册
def test_register():
    url = f"{BASE_URL}/auth/register"
    payload = {
        "username": "test_user",
        "email": "test_user@example.com",
        "password": "password123",
        "full_name": "Test User"
    }
    response = requests.post(url, json=payload)
    print("注册接口响应:", response.status_code, response.json())
    print("注册接口响应原始内容:", response.text)

# 测试用户登录
def test_login():
    url = f"{BASE_URL}/auth/login"
    payload = {
        "username": "test_user",
        "password": "password123"
    }
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    response = requests.post(url, data=payload, headers=headers)
    print("登录接口响应:", response.status_code, response.json())

if __name__ == "__main__":
    print("测试用户注册...")
    test_register()

    print("测试用户登录...")
    test_login()
