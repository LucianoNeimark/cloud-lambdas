// App.js
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import HomePage from './pages/home_page';
import NavigationBar from './components/navbar/navbar';
import CreatePage from './pages/create_page';


import './App.css';

function App() {
  return (
    <Router>
      <div>
        <NavigationBar />
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/crear" element={<CreatePage />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
