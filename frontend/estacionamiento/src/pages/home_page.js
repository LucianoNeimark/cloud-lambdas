import React, { useState, useEffect } from 'react';
import './home_page.css';
import { regionOptions } from '../constants';


function HomePage() {
    const [parkingLots, setParkingLots] = useState([]);
    const [selectedParkingLotId, setSelectedParkingLotId] = useState('');
    const [occupiedSpaces, setOccupiedSpaces] = useState(0);
    const [totalSpaces, setTotalSpaces] = useState(0);
    const [freeSpaces, setFreeSpaces] = useState(0);
    const [selectedRegion, setSelectedRegion] = useState('all');

    // Edit form state
    const [editMode, setEditMode] = useState(false);
    const [name, setName] = useState('');
    const [capacity, setCapacity] = useState(0);

    const base_url = process.env.REACT_APP_API_URL;

    useEffect(() => {
        setFreeSpaces(totalSpaces - occupiedSpaces);
    }, [occupiedSpaces, totalSpaces]);

    const fetchRegionParkingLots = async (region) => {
        try {
            // Fetch region parking lots from API
            const response = await fetch(`${base_url}/parking/${region}`);
            if (!response.ok) {
                throw new Error('Failed to fetch region parking lots');
            }
            const data = await response.json();
            let parsedData = []
            for (let i = 0; i < data.length; i++) {
                parsedData.push({
                    id: data[i].id.S,
                    name: data[i].name.S,
                    totalSpaces: data[i].capacity.N,
                    occupiedSpaces: data[i].occupied_qty.N
                })
            }
            setParkingLots(parsedData);
        } catch (error) {
            console.error('Error fetching region parking lots:', error);
        }
    };

    const editParkingLot = async (e) => {
        e.preventDefault();
        try {
            const response = await fetch(`${base_url}/parking/${selectedRegion}/${selectedParkingLotId}`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ name: name, capacity: capacity }),
            });
            if (!response.ok) {
                throw new Error('Failed to edit parking lot');
            }
            parkingLots.find(lot => lot.id === selectedParkingLotId).name = name;
            parkingLots.find(lot => lot.id === selectedParkingLotId).totalSpaces = capacity;
            setParkingLots([...parkingLots]);
            setTotalSpaces(capacity);
        } catch (error) {
            console.error('Error editing parking lot:', error);
        }
        setEditMode(false);
    };

    const handleRegionChange = (e) => {
        const selectedRegion = e.target.value;
        setSelectedRegion(selectedRegion);
        fetchRegionParkingLots(selectedRegion);
        setSelectedParkingLotId('');
    };

    const handleParkingLotChange = (e) => {
        const selectedLotId = e.target.value;
        const selectedLot = parkingLots.find(lot => lot.id === selectedLotId);
        setSelectedParkingLotId(selectedLot.id);
        setName(selectedLot.name);
        setCapacity(selectedLot.totalSpaces);
        if (selectedLot) {
            setOccupiedSpaces(selectedLot.occupiedSpaces);
            setTotalSpaces(selectedLot.totalSpaces);
        }
    };

    const handleIncreaseOccupiedSpaces = async () => {
        try {
            // POST another API endpoint to increase the occupied spaces
            const response = await fetch(`${base_url}/parking/${selectedRegion}/${selectedParkingLotId}/lot`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                }
            });
            if (!response.ok) {
                throw new Error('Failed to increase occupied spaces');
            }
            const data = await response.json();
            setOccupiedSpaces(data.occupied_qty);
        }
        catch (error) {
            console.error('Error increasing occupied spaces:', error);
        }
    };

    const handleDecreaseOccupiedSpaces = async () => {
        try {
            const response = await fetch(`${base_url}/parking/${selectedRegion}/${selectedParkingLotId}/lot`, {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json',
                }
            });
            if (!response.ok) {
                throw new Error('Failed to increase occupied spaces');
            }
            const data = await response.json();
            setOccupiedSpaces(data.occupied_qty);
        }
        catch (error) {
            console.error('Error increasing occupied spaces:', error);
        }
    };

    return (
        <>
            {!editMode ? (
                <div className="page-container">
                    <h2 className="page-title">¿A dónde deseas ir?</h2>
                    <div className="select-container">
                        <label className="select-label">Selecciona un barrio:</label>
                        <select value={selectedRegion} onChange={handleRegionChange} className="select-dropdown">
                            <option value='all'>Selecciona un barrio</option>
                            {regionOptions.map(region => (
                                <option key={region} value={region}>{region}</option>
                            ))}
                        </select>
                    </div>
                    {selectedRegion !== 'all' && parkingLots.length > 0 && ( // Render second dropdown only if region is selected
                        <div className="select-container">
                            <label className="select-label">Selecciona un estacionamiento:</label>
                            <select value={selectedParkingLotId} onChange={handleParkingLotChange} className="select-dropdown">
                                <option value="">Selecciona un estacionamiento</option>
                                {parkingLots.map(parkingLot => (
                                    <option key={parkingLot.id} value={parkingLot.id}>{parkingLot.name}</option>
                                ))}
                            </select>
                        </div>
                    )}
                    {selectedRegion != 'all' && parkingLots.length === 0 && (
                        <p className="no-parking-lots">No hay estacionamientos disponibles</p>
                    )
                    }
                    {selectedParkingLotId && (
                        <div className="parking-info-container">
                            <div className="parking-inner-container">
                                <p className="parking-info">Espacios libres: {freeSpaces} / {totalSpaces}</p>
                                <button className="button" onClick={() => setEditMode(true)}>Editar</button>
                            </div>
                            <div className="button-container">
                                <button onClick={handleIncreaseOccupiedSpaces} className="button">Ocupar espacio</button>
                                <button onClick={handleDecreaseOccupiedSpaces} className="button">Dejar espacio</button>
                            </div>
                        </div>
                    )}
                </div>
            ) : (
                <div className="form-container">
                    <form onSubmit={editParkingLot}>
                        <div className="form-group">
                            <label className="form-label">Nombre:</label>
                            <input type="text" className="form-input" value={name} onChange={(e) => setName(e.target.value)} />
                        </div>
                        <div className="form-group">
                            <label className="form-label">Capacidad:</label>
                            <input type="number" className="form-input" value={capacity} onChange={(e) => setCapacity(e.target.value)} />
                        </div>
                        <div className="button-container">
                            <button onClick={() => setEditMode(false)} className="button">Cancelar</button>
                            <button type="submit" className="button">Confirmar</button>
                        </div>
                    </form>
                </div>
            )}

        </>
    );
}

export default HomePage;
