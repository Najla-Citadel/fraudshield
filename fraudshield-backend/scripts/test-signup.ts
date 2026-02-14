import axios from 'axios';

const API_BASE_URL = 'http://localhost:3000/api/v1';

async function testSignup() {
    console.log('🚀 Starting Signup Tests...');

    // 1. Test missing fields
    try {
        console.log('Testing missing fields...');
        await axios.post(`${API_BASE_URL}/auth/signup`, {});
    } catch (error: any) {
        console.log(`✅ Correctly caught error: ${error.response?.status} - ${error.response?.data?.message}`);
    }

    // 2. Test short password
    try {
        console.log('Testing short password...');
        await axios.post(`${API_BASE_URL}/auth/signup`, {
            email: 'test@example.com',
            password: '123'
        });
    } catch (error: any) {
        console.log(`✅ Correctly caught error: ${error.response?.status} - ${error.response?.data?.message}`);
    }

    // 3. Test valid signup (Note: This might fail if the user already exists, but we are looking for NO 500)
    try {
        console.log('Testing valid signup...');
        const email = `test_${Date.now()}@example.com`;
        const response = await axios.post(`${API_BASE_URL}/auth/signup`, {
            email: email,
            password: 'password123',
            fullName: 'Test User'
        });
        console.log(`✅ Signup success: ${response.status}`);
    } catch (error: any) {
        if (error.response?.status === 400 && error.response?.data?.message === 'Email already in use') {
            console.log('✅ Correctly handled existing user');
        } else {
            console.log(`❌ Unexpected error: ${error.response?.status || error.message}`);
            if (error.response?.data) console.log(error.response.data);
        }
    }
}

testSignup();
