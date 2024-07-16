// NavigationBar.js
import React, { useState, useEffect } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import './navbar.css';
import { jwtDecode } from 'jwt-decode';


function NavigationBar() {
    const [isAdmin, setIsAdmin] = useState(false);
    
    const location = useLocation();

    useEffect(() => {
        let token = localStorage.getItem('token');
        if(token === 'null' || token === null) {
            console.log('Token not found');
            const hash = location.hash.substring(1); // Elimina el primer carácter (#)
            const queryParams = new URLSearchParams(hash);
            const newToken = queryParams.get('id_token');
            localStorage.setItem('token', newToken);
            if(newToken === null){
                window.location.href = process.env.LOGIN_URL;            
            }
            token = newToken;
        }
        try {
            const decodedToken = jwtDecode(token);
            if(decodedToken && decodedToken['cognito:groups']) {
                setIsAdmin(decodedToken['cognito:groups'].includes('estacionamiento-admin'));
            }
            console.log('is admin:', isAdmin);
        } catch (error) {
            console.error('Error decoding token:', error);
        }
    }, []);


    return (
        <nav className="navbar">
            <h1 className="navbar-title">Estacionamiento</h1>
            <ul className="navbar-list">
                <li className="navbar-item">
                    <NavLink exact to="/" className="navbar-link">Inicio</NavLink>
                </li>
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
