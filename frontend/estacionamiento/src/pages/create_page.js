import React, { useState } from 'react';
import './create_page.css';
import { regionOptions } from '../constants';
import SlAlert from '@shoelace-style/shoelace/dist/react/alert';
import SlIcon from '@shoelace-style/shoelace/dist/react/icon';

function CreatePage() {
    const [region, setRegion] = useState(regionOptions[0]);
    const [name, setName] = useState('');
    const [totalSpaces, setTotalSpaces] = useState('');
    const [showError, setShowError] = useState(false);
    const [showSuccess, setShowSuccess] = useState(false);
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
            setShowSuccess(true)
        } catch (error) {
            console.error('Error creating parking lot:', error);
            // alert('Error creando estacionamiento');
            setShowError(true)
        }
    };

    return (
        <>
            <div style={{ "position": "absolute", "right": "2em", "top": "2em" }}>
                <SlAlert variant="danger" open={showError} duration="6000" onSlHide={() => setShowError(false)}>
                    <SlIcon slot="icon" name="exclamation-octagon"></SlIcon>
                    <strong>Error creando el estacionamiento</strong><br />
                    Intentalo de nuevo mas tarde
                </SlAlert>
            </div>
            <div style={{ "position": "absolute", "right": "2em", "top": "2em" }}>
                <SlAlert variant="success" open={showSuccess} duration="3000" onSlHide={() => setShowSuccess(false)}>
                    <SlIcon slot="icon" name="exclamation-octagon"></SlIcon>
                    <strong>Estacionamiento creado exitosamente</strong><br />
                </SlAlert>
            </div>
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
                        <input type="text" className="form-input" value={name} onChange={(e) => setName(e.target.value)}
                            minLength={1} required
                        />
                    </div>
                    <div className="form-group">
                        <label className="form-label">Capacidad:</label>
                        <input type="number" className="form-input" value={totalSpaces} onChange={(e) => setTotalSpaces(e.target.value)}
                            min={1} required />
                    </div>
                    <button type="submit" className="form-button">Crear</button>
                </form>
            </div>
        </>
    );
}

export default CreatePage;
