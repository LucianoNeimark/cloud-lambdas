// NavigationBar.js
import React, { useState, useEffect } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import './navbar.css';
import { jwtDecode } from 'jwt-decode';


function NavigationBar() {
    const [isAdmin, setIsAdmin] = useState(false);

    const location = useLocation();

    const fetchToken = async () => {
        let token = localStorage.getItem('token');
        if (token === 'null' || token === null) {
            console.log('Token not found');
            const queryParams = new URLSearchParams(location.search);
            const newCode = queryParams.get('code');
            if (newCode === null || newCode === 'null') {
                console.log('Redirecting to login');
                window.location.href = process.env.REACT_APP_LOGIN_URL;
                return;
            }
            const newTokens = await fetch(process.env.REACT_APP_TOKEN_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: new URLSearchParams({
                    grant_type: 'authorization_code',
                    client_id: process.env.REACT_APP_CLIENT_ID,
                    code: newCode,
                    redirect_uri: process.env.REACT_APP_REDIRECT_URL
                })
            }).then(response => response.json()).then(data => data).catch(error => {
                console.error('Error fetching token:', error);
                return null;
            });

            const newToken = newTokens.id_token;
            const newRefreshToken = newTokens.refresh_token;

            localStorage.setItem('token', newToken);
            localStorage.setItem('refresh_token', newRefreshToken);
            if (newToken === null || newToken === 'null') {
                console.log('Redirecting to login');
                window.location.href = process.env.REACT_APP_LOGIN_URL;
                return;
            }
            token = newToken;
            try {
                const decodedToken = jwtDecode(token);
                if (decodedToken && decodedToken['cognito:groups']) {
                    setIsAdmin(decodedToken['cognito:groups'].includes('estacionamiento-admin'));
                }
                console.log('is admin:', isAdmin);
            } catch (error) {
                console.error('Error decoding token:', error);
            }
        }
    };


    useEffect(() => {
        fetchToken();
    }, []);

    const logout = async () => {
        await fetch(process.env.REACT_APP_LOGOUT_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
                client_id: process.env.REACT_APP_CLIENT_ID,
                token: localStorage.getItem('refresh_token')
            })
        });


        document.cookie = 'cognito=; path=/; domain=.estacionamiento-app-auth-7d8e2a44c26c2d1d.auth.us-east-1.amazoncognito.com; expires=Thu, 01 Jan 1970 00:00:01 GMT;';

        localStorage.setItem('token', null);
        localStorage.setItem('refresh_token', null);

        window.location.href = process.env.REACT_APP_LOGIN_URL;
    }

    return (
        <nav className="navbar">
            <h1 className="navbar-title">Estacionamiento</h1>
            <ul className="navbar-list">
                <li className="navbar-item">
                    <NavLink exact to="/" className="navbar-link">Inicio</NavLink>
                </li>
                {/* <li className="navbar-item">
                    <NavLink onClick={logout} className="navbar-link">Logout</NavLink>
                </li> */}
                <li className="navbar-item">
                    {
                        isAdmin && (
                            <NavLink to="/crear" className="navbar-link">Nuevo estacionamiento</NavLink>
                        )
                    }
                </li>
            </ul>
        </nav>
    );
}

export default NavigationBar;
