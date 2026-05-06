import requests
import json
import sys
import random

# Tinta este serverul Node.js local (backend/server.js)
API_URL = "http://localhost:3000/api"

def test_backend_auth_flow():
    print("--- Starting Backend Auth API Integration Tests ---")
    
    # Generăm un username aleatoriu ca să nu se suprapună testele între ele (dacă re-rulăm)
    test_user = f"qa_tester_{random.randint(1000, 9999)}"
    test_pass = "secure_password_123!"
    
    # ========================================================
    # TEST 1: Registration Endpoint (/register)
    # Ne așteptăm să se creeze contul și să ne returneze status 200
    # ========================================================
    print(f"\n[Test 1] Încercăm să înregistrăm utilizatorul: {test_user}")
    try:
        reg_response = requests.post(f"{API_URL}/register", json={
            "username": test_user,
            "password": test_pass
        }, timeout=5)
        
        if reg_response.status_code == 200:
            print("✅ SUCCES: Utilizatorul a fost înregistrat corect în baza de date temporară.")
        else:
            print(f"❌ EROARE: Serverul a returnat un cod neașteptat: {reg_response.status_code}")
            sys.exit(1)
            
    except requests.exceptions.ConnectionError:
        print("❌ EROARE CRITICĂ: Nu mă pot conecta la serverul Node.js.")
        print("💡 Ai pornit serverul backend? Rulează `node backend/server.js` în alt terminal!")
        sys.exit(1)
        
    # ========================================================
    # TEST 2: Login Failure (/login)
    # Testăm securitatea - ne așteptăm ca o parolă greșită să fie refuzată (401)
    # ========================================================
    print(f"\n[Test 2] Încercăm să ne logăm cu o parolă GREȘITĂ...")
    bad_login_response = requests.post(f"{API_URL}/login", json={
        "username": test_user,
        "password": "wrongpassword!"
    }, timeout=5)
    
    if bad_login_response.status_code == 401:
         print("✅ SUCCES: Serverul a refuzat parola greșită (Status 401: Unauthorized) așa cum trebuie.")
    else:
         print(f"❌ EROARE DE SECURITATE: Serverul nu a refuzat autentificarea! Status primit: {bad_login_response.status_code}")
         sys.exit(1)
         
    # ========================================================
    # TEST 3: Login Success & JWT Generation (/login)
    # Testăm autentificarea corectă - ne așteptăm la un token JWT (200 OK)
    # ========================================================
    print(f"\n[Test 3] Încercăm să ne logăm cu parola CORECRĂ...")
    good_login_response = requests.post(f"{API_URL}/login", json={
        "username": test_user,
        "password": test_pass
    }, timeout=5)
    
    if good_login_response.status_code == 200:
        data = good_login_response.json()
        if "token" in data:
            print("✅ SUCCES: Login-ul a reușit și serverul ne-a oferit un JWT valid!")
            print(f"   🎟️ Token primit: {data['token'][:20]}...[TRUNCATED]")
        else:
            print("❌ EROARE: Serverul a răspuns OK, dar nu a generat niciun Token (JWT)!")
            sys.exit(1)
    else:
        print(f"❌ EROARE: Autentificarea validă a fost refuzată! Status primit: {good_login_response.status_code}")
        sys.exit(1)

    print("\n--- Toate testele API au trecut cu brio! Backend-ul este solid. ---")
    sys.exit(0)

if __name__ == "__main__":
    test_backend_auth_flow()
