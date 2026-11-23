import os
from dotenv import load_dotenv
from supabase import create_client
from postgrest.exceptions import APIError

load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")

def verify_rls_policies():
    anon_client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

    # 1. Unauthenticated anon SELECT (blocked by table privileges)
    try:
        anon_client.table("books").select("*").execute()
        raise AssertionError("Expected anon SELECT to fail")
    except APIError as err:
        assert err.code == "42501"
        print(f"1. PASS - Anon SELECT blocked: {err.code} ({err.message})")

    # 2. Unauthenticated anon INSERT (blocked by table privileges)
    try:
        anon_client.table("categories").insert({"name": "Anon Test"}).execute()
        raise AssertionError("Expected anon INSERT to fail")
    except APIError as err:
        assert err.code == "42501"
        print(f"2. PASS - Anon INSERT blocked: {err.code} ({err.message})")

    # 3. Signed-in non-staff INSERT (blocked by RLS policy evaluation)
    nonstaff_client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
    nonstaff_client.auth.sign_in_with_password({
        "email": os.getenv("TEST_NONSTAFF_EMAIL"),
        "password": os.getenv("TEST_NONSTAFF_PASSWORD"),
    })
    try:
        nonstaff_client.table("categories").insert({"name": "Non-Staff Test"}).execute()
        raise AssertionError("Expected non-staff INSERT to fail")
    except APIError as err:
        assert err.code == "42501"
        print(f"3. PASS - Non-staff INSERT blocked: {err.code} ({err.message})")

    # 4. Signed-in staff INSERT & DELETE (succeeds)
    staff_client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
    staff_client.auth.sign_in_with_password({
        "email": os.getenv("TEST_STAFF_EMAIL"),
        "password": os.getenv("TEST_STAFF_PASSWORD"),
    })
    insert_res = staff_client.table("categories").insert({"name": "Staff Test Category"}).execute()
    assert len(insert_res.data) == 1
    print("4. PASS - Staff INSERT succeeded:", insert_res.data["id"])

    staff_client.table("categories").delete().eq("name", "Staff Test Category").execute()
    print("5. PASS - Staff DELETE cleanup succeeded.")

if __name__ == "__main__":
    verify_rls_policies()
