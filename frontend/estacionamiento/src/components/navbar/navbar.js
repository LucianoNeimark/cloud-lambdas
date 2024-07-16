// NavigationBar.js
import React, { useState, useEffect } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import './navbar.css';
import { jwtDecode } from 'jwt-decode';

const loginParams = new URLSearchParams({
    client_id: process.env.REACT_APP_CLIENT_ID,
    redirect_uri: process.env.REACT_APP_REDIRECT_URL,
    response_type: 'code'
});
const loginUrl = process.env.REACT_APP_COGNITO_URL + "login?" + loginParams.toString();

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
                window.location.href = loginUrl;
                return;
            }
            const newTokens = await fetch(process.env.REACT_APP_COGNITO_URL + "oauth2/token", {
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
                window.location.href = loginUrl;
                return;
            }
            token = newToken;
        }
        try {
            const decodedToken = jwtDecode(token);
            if (decodedToken && decodedToken['cognito:groups']) {
                setIsAdmin(decodedToken['cognito:groups'].includes('estacionamiento-admin'));
            }
            console.log('is admin:', isAdmin);
        } catch (error) {
            console.error('Error decoding token:', error);
        }

    };


    useEffect(() => {
        fetchToken();
    }, []);

    const logout = async () => {
        let queryParams = new URLSearchParams();
        queryParams.append('client_id', process.env.REACT_APP_CLIENT_ID);
        queryParams.append('redirect_uri', process.env.REACT_APP_REDIRECT_URL);
        queryParams.append('response_type', 'code');

        localStorage.setItem('token', null);
        localStorage.setItem('refresh_token', null);

        window.location.href = process.env.REACT_APP_COGNITO_URL + "logout?" + queryParams.toString();
    }

    const become_creator = async () => {
        try {
            const response = await fetch(`${process.env.REACT_APP_API_URL}/become-admin`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('token')}`,
                }
            });
            if (!response.ok) {
                throw new Error('Failed to become owner');
            }
            setIsAdmin(true);
            logout();
        } catch (error) {
            console.error('Error becoming owner:', error);
        }
    }

    return (
        <nav className="navbar">
            <h1 className="navbar-title">Estacionamiento</h1>
            <ul className="navbar-list">
                <li className="navbar-item">
                    <NavLink exact to="/" className="navbar-link">Inicio</NavLink>
                </li>
                <li className="navbar-item">
                    <NavLink onClick={logout} className="navbar-link">Cerrar sesión</NavLink>
                </li>
                {
                    isAdmin && (
                        <li className="navbar-item">
                            <NavLink to="/crear" className="navbar-link">Nuevo estacionamiento</NavLink>
                        </li>
                    )
                }
                {
                    !isAdmin && (
                        <li className="navbar-item">
                            <NavLink onClick={become_creator} className="navbar-link">Convertirse en dueño</NavLink>
                        </li>
                    )
                }
            </ul>
        </nav>
    );
}

export default NavigationBar;
