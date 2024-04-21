import React, { useState } from 'react';
import './create_page.css';
import { regionOptions } from '../constants';

function CreatePage() {
    const [region, setRegion] = useState(regionOptions[0]);
    const [name, setName] = useState('');
    const [totalSpaces, setTotalSpaces] = useState('');

    const base_url = process.env.REACT_APP_API_URL;

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const response = await fetch(`${base_url}/parking/${region}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ name: name, capacity: totalSpaces }),
            });
            if (!response.ok) {
                throw new Error('Failed to create parking lot');
            }
            alert('Estacionamiento creado exitosamente');
        } catch (error) {
            console.error('Error creating parking lot:', error);
            alert('Error creando estacionamiento');
        }
    };

    return (
        <div className="form-container">
            <form onSubmit={handleSubmit}>
                <div className="form-group">
                    <label className="form-label">Barrio:</label>
                    <select value={region} onChange={(e) => setRegion(e.target.value)} className="form-input">
                        {regionOptions.map((region, index) => (
                            <option key={index} value={region}>{region}</option>
                        ))}
                    </select>
                </div>
                <div className="form-group">
                    <label className="form-label">Nombre:</label>
                    <input type="text" className="form-input" value={name} onChange={(e) => setName(e.target.value)} />
                </div>
                <div className="form-group">
                    <label className="form-label">Capacidad:</label>
                    <input type="number" className="form-input" value={totalSpaces} onChange={(e) => setTotalSpaces(e.target.value)} />
                </div>
                <button type="submit" className="form-button">Crear</button>
            </form>
        </div>
    );
}

export default CreatePage;
