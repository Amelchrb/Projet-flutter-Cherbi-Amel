# python -m venv venv
# venv\Scripts\activate    

# pip install flask pytest
# pip install transformers
# pip install flask
# pip install torch torchvision torchaudio
# pip install flask_cors
# pip install "accelerate>=0.26.0"


import pytest
import sys
import os

# Ajouter le répertoire parent (racine) au chemin d'importation
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))) 
from ModelIA_pretrained import app

@pytest.fixture
def client():
    # Active le mode TESTING
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_chat_valid_message(client):
    """Test si l'API répond correctement à une entrée valide."""
    response = client.post('/chat', json={"message": "Bonjour"})
    assert response.status_code == 200  # Statut attendu
    data = response.get_json()
    assert "response" in data
    assert "generation_time" in data
    assert len(data["response"]) > 0  # La réponse ne doit pas être vide

def test_chat_empty_message(client):
    """Test si l'API gère correctement un message vide."""
    response = client.post('/chat', json={"message": ""})
    assert response.status_code == 400
    data = response.get_json()
    assert data["error"] == "Le champ 'message' est vide."

def test_chat_performance(client):
    """Test si le temps de réponse est inférieur à 2 secondes."""
    import time
    start_time = time.time()
    response = client.post('/chat', json={"message": "Quel temps fait-il aujourd'hui ?"})
    end_time = time.time()

    assert response.status_code == 200
    data = response.get_json()
    assert "response" in data
    assert (end_time - start_time) <= 2.0  # Vérifie que le temps est inférieur à 2 secondes


def test_chat_special_characters(client):
    """Test si l'API gère des caractères spéciaux."""
    response = client.post('/chat', json={"message": "!?@#$%^&*()😊"})
    assert response.status_code == 200
    data = response.get_json()
    assert "response" in data


def test_chat_sql_injection(client):
    """Test si l'API est sécurisée contre une tentative d'injection."""
    injection_payload = "' OR '1'='1'; DROP TABLE users; --"
    response = client.post('/chat', json={"message": injection_payload})
    assert response.status_code == 200
    data = response.get_json()
    assert "response" in data  # L'API ne doit pas planter
