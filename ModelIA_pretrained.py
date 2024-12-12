# #Configuration d'un environnemet virtuel.
# # python -m venv env
# # env\Scripts\activate

# #Installation pip et setuptools
# # python -m pip install --upgrade pip setuptools

# #Installation de torch
# # pip install torch torchvision torchaudio

# # Installation du package transformers 
# # pip install transformers

#Utilisation de Flask pour l'API
#pip install flask

from flask import Flask, request, jsonify
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

prompt="Expliquez la photosynthèse en termes simples."



# # GPT-Neo est un modèle open source 
# # Chargement d'un modèle GPT-Neo pré-entraîné
# generator = pipeline("text-generation", model="EleutherAI/gpt-neo-125M")
# # model="EleutherAI/gpt-neo-125M" : Modèle GPT-Neo

# # Test d'une génération de texte
# # prompt = "Expliquez le concept des réseaux neuronaux en termes simples, comme si vous l'expliquiez à un enfant de 10 ans. Incluez un exemple pour faciliter la compréhension."
# result = generator(
#     prompt,
#     max_length=300, # Longueur maximale de la réponse générée
#     num_return_sequences=1, # Nombre de réponses générées
#     do_sample=True,  # Active le sampling aléatoire
#     top_p=0.9,       # Limite la génération aux mots les plus probables cumulant 90 %
#     temperature=0.8, # Controle la créativité : Plus c'est bas, moins il y aura de créativité dans les réponses. 
#     truncation=True  # Contrôle la diversité
# )

# print(result)



# # Flan-T5 est un modèle open source optimisé pour les tâches conversationnelles
# # Chargement d'un modèle Flan-T5 pré-entraîné
# generator = pipeline("text2text-generation", model="google/flan-t5-large")

# # Test d'une génération de texte avec Flan-T5
# # prompt = "Explain the concept of neural networks in simple terms as if explaining it to a 10-year-old. Include an example to make it easy to understand."
# result = generator(
#     prompt,
#     max_length=300, # Longueur maximale de la réponse générée
#     num_return_sequences=1, # Nombre de réponses générées
#     do_sample=True,  # Active le sampling aléatoire
#     top_p=0.9,       # Limite la génération aux mots les plus probables cumulant 90 %
#     temperature=0.8,# Contrôle la créativité : Plus c'est bas, moins il y aura de créativité dans les réponses
#     eos_token_id=generator.tokenizer.eos_token_id 
# )

# # Affichage du résultat généré par Flan-T5
# print("Réponse générée par Flan-T5 :")
# print(result)





#BLOOM
# from transformers import AutoModelForCausalLM, AutoTokenizer

# # Charger le modèle et le tokenizer
# model_name = "bigscience/bloom-560m"
# tokenizer = AutoTokenizer.from_pretrained(model_name)
# model = AutoModelForCausalLM.from_pretrained(model_name)

# # Prompt d'entrée
# prompt = "Explique-moi ce qu'est la photosynthèse :"

# # Tokenisation
# inputs = tokenizer(prompt, return_tensors="pt")

# # Génération avec des paramètres améliorés
# output = model.generate(
#     inputs["input_ids"], 
#     max_length=100,        # Longueur maximale ajustée
#     do_sample=True,        # Activation de l'échantillonnage
#     temperature=0.7,       # Contrôle de la créativité
#     top_p=0.9,             # Nucleus sampling
#     repetition_penalty=1.5 # Réduction des répétitions
# )

# # Décodage de la sortie
# response = tokenizer.decode(output[0], skip_special_tokens=True)
# print("Réponse générée :")
# print(response)




# #MISTRAL: TROP LOURD
# from transformers import AutoTokenizer, AutoModelForCausalLM

# model_name = "mistralai/Mistral-7B-v0.1"
# access_token = "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"

# # Charger le tokenizer et le modèle
# tokenizer = AutoTokenizer.from_pretrained(model_name, token=access_token)
# model = AutoModelForCausalLM.from_pretrained(model_name, token=access_token)

# # Prompt pour la génération de texte
# prompt = "Expliquez le concept des réseaux neuronaux en termes simples, comme si vous l'expliquiez à un enfant de 10 ans."
# inputs = tokenizer(prompt, return_tensors="pt")

# # Génération de texte
# outputs = model.generate(inputs["input_ids"], max_length=100, do_sample=True, top_p=0.9, temperature=0.8)

# # Décodage et affichage du résultat
# response = tokenizer.decode(outputs[0], skip_special_tokens=True)
# print("Réponse générée par Mistral :")
# print(response)






# # GPT-3 via l’API d’OpenAI :  Il est plus performant, mais nécessite un compte OpenAI et de payer.
# #Installation du SDK OpenAI
# #pip install openai

# # Configure la clé API
# import os
# from openai import OpenAI

# # Configure la clé API depuis une variable d'environnement
# api_key = os.getenv("OPENAI_API_KEY")

# if not api_key:
#     raise ValueError("La clé API OpenAI n'est pas définie dans les variables d'environnement. "
#                      "Ajoutez 'OPENAI_API_KEY' à vos variables d'environnement.")

# # Initialisation du client OpenAI
# client = OpenAI(api_key=api_key)

# # Fonction pour générer une réponse à partir d'un prompt
# def obtenir_reponse(prompt):
#     try:
#         response = client.chat.completions.create(
#             model="gpt-3.5-turbo",
#             messages=[
#                 {"role": "system", "content": "Vous êtes un assistant utile."},
#                 {"role": "user", "content": prompt}
#             ],
#             max_tokens=150,
#             temperature=0.7,
#         )
#         return response.choices[0].message.content.strip()
#     except Exception as e:
#         return f"Une erreur est survenue : {e}"

# # Exemple d'utilisation
# if __name__ == "__main__":
#     prompt = input("Entrez votre prompt : ")
#     reponse = obtenir_reponse(prompt)
#     print(f"Réponse du modèle : {reponse}") 




#QWEN 1.5B (TROP LENT):
#pip install accelerate

# from transformers import AutoModelForCausalLM, AutoTokenizer

# # Chargement du modèle Qwen et du tokenizer pour générer des réponses.
# model_name = "Qwen/Qwen2.5-1.5B-Instruct"
# model = AutoModelForCausalLM.from_pretrained(
#     model_name,
#     torch_dtype="auto",  # Adapte automatiquement le type de données au matériel.
#     device_map="auto"    # Place le modèle sur les ressources disponibles (GPU/CPU).
# )
# tokenizer = AutoTokenizer.from_pretrained(model_name)

# # Création d'un prompt avec un rôle système et utilisateur.
# prompt = "Give me a short introduction to large language model."
# messages = [
#     {"role": "system", "content": "Tu es Qwen, créé par Alibaba Cloud. Tu es un assistant intelligent."},
#     {"role": "user", "content": prompt}
# ]

# # Formatage des messages pour les passer au modèle.
# text = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)

# # Préparation des entrées pour le modèle en les convertissant en tenseurs.
# model_inputs = tokenizer([text], return_tensors="pt").to(model.device)

# # Génération de la réponse à partir du modèle, limitée à 512 tokens.
# generated_ids = model.generate(**model_inputs, max_new_tokens=512)

# # Extraction et décodage de la réponse générée.
# generated_ids = [output_ids[len(input_ids):] for input_ids, output_ids in zip(model_inputs.input_ids, generated_ids)]
# response = tokenizer.batch_decode(generated_ids, skip_special_tokens=True)[0]
# print(response)





#QWEN 0.5B (UN PEU LENT MAIS RESULTAT SATISFAISANT):
# Importation des outils nécessaires pour utiliser le modèle et le tokenizer

from transformers import AutoModelForCausalLM, AutoTokenizer
import time  # Pour mesurer le temps de génération
from flask_cors import CORS  # Importer flask-cors

app = Flask(__name__)
CORS(app)

# Charger le modèle Qwen et le tokenizer
model_name = "Qwen/Qwen2.5-0.5B-Instruct"
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.float32,  # Assurez-vous que le modèle fonctionne bien en float32
    device_map="cpu"           # Forcer l'utilisation du CPU
)
tokenizer = AutoTokenizer.from_pretrained(model_name)

@app.route('/chat', methods=['POST'])
def chat():
    try:
        # Récupérer le message utilisateur
        data = request.get_json(force=True)
        user_input = data.get('message', '').strip()
        if not user_input:
            return jsonify({"error": "Le champ 'message' est vide."}), 400

        # Préparer le prompt pour le modèle
        messages = [
            {"role": "system", "content": "Tu es Qwen, créé par Alibaba Cloud. Tu es un assistant intelligent."},
            {"role": "user", "content": user_input}
        ]
        text = tokenizer.apply_chat_template(
            messages,
            tokenize=False,  # Pas besoin de transformer en tokens immédiatement
            add_generation_prompt=True  # Ajout d'un indicateur pour guider la génération
        )
        model_inputs = tokenizer([text], return_tensors="pt").to(model.device)

        # Mesurer le temps de génération
        start_time = time.time()

        # Génération de la réponse
        generated_ids = model.generate(
            **model_inputs,
            max_new_tokens=512,  # Limitation pour éviter les phrases trop longues
            temperature=0.6,     # Ajustement pour la cohérence
            top_p=0.95           # Réduction des incohérences
        )

        # Mesure de fin de génération
        end_time = time.time()
        print(f"Temps de génération : {end_time - start_time:.2f} secondes")

        # Décodage de la réponse générée
        generated_ids = [
            output_ids[len(input_ids):] for input_ids, output_ids in zip(model_inputs.input_ids, generated_ids)
        ]
        response = tokenizer.batch_decode(generated_ids, skip_special_tokens=True)[0]

        # Retourner la réponse directement
        return jsonify({"response": response.strip()}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)