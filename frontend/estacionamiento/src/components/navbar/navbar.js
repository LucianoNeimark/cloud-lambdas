// NavigationBar.js
import React from 'react';
import { NavLink } from 'react-router-dom';
import './navbar.css';

function NavigationBar() {
    return (
        <nav className="navbar">
            <h1 className="navbar-title">Estacionamiento</h1>
            <ul className="navbar-list">
                <li className="navbar-item">
                    <NavLink exact to="/" className="navbar-link">Inicio</NavLink>
                </li>
                <li className="navbar-item">
                    <NavLink to="/crear" className="navbar-link">Nuevo estacionamiento</NavLink>
                </li>
            </ul>
        </nav>
    );
}

export default NavigationBar;
