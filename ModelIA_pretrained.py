# #Configuration d'un environnemet virtuel.
# # python -m venv env
# # env\Scripts\activate

# #Installation pip et setuptools
# # python -m pip install --upgrade pip setuptools

# #Installation de torch
# # pip install torch torchvision torchaudio

# # Installation du package transformers 
# # pip install transformers

from transformers import pipeline
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

# import openai

# # Configure la clé API
# # openai.api_key = "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"

# import os
# from openai import OpenAI

# # Assurez-vous que votre clé API est stockée dans la variable d'environnement 'OPENAI_API_KEY'
# api_key = "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"

# if not api_key:
#     raise ValueError("La clé API OpenAI n'est pas définie dans les variables d'environnement.")

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

# Nom du modèle Qwen sélectionné (Qwen 2.5-0.5B Instruct)
model_name = "Qwen/Qwen2.5-0.5B-Instruct"

# Chargement du modèle pour fonctionner uniquement sur le CPU
# On spécifie que le type de données est automatique, mais qu'on utilise seulement le CPU
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.float32,  # Assurez-vous que le modèle fonctionne bien en float32
    device_map="cpu"  # Forcer l'utilisation du CPU
)

# Chargement du tokenizer qui permet de transformer le texte en tokens utilisables par le modèle
tokenizer = AutoTokenizer.from_pretrained(model_name)

# Interface utilisateur interactive
print("Bienvenue dans l'assistant Qwen ! Tapez 'exit' pour quitter.")
while True:
    # Demande du prompt utilisateur
    user_input = input("Tapez votre question : ")
    
    # Condition pour quitter la boucle
    if user_input.lower() == "exit":
        print("Merci d'avoir utilisé Qwen. À bientôt !")
        break

    # Configuration du contexte conversationnel pour donner une "personnalité" au modèle
    messages = [
        {"role": "system", "content": "Tu es Qwen, créé par Alibaba Cloud. Tu es un assistant intelligent."},
        {"role": "user", "content": user_input}
    ]

    # Préparation du texte pour le modèle en format conversationnel
    # Le texte est formaté pour être compris comme un échange entre un utilisateur et un assistant
    text = tokenizer.apply_chat_template(
        messages,
        tokenize=False,  # Pas besoin de transformer en tokens immédiatement
        add_generation_prompt=True  # Ajout d'un indicateur pour guider la génération
    )

    # Transformation du texte en tenseurs utilisables par le modèle
    model_inputs = tokenizer([text], return_tensors="pt").to(model.device)

    # Début de la mesure du temps de génération pour évaluer les performances
    start_time = time.time()

    # Génération de la réponse par le modèle
    try:
        # On limite le nombre maximum de tokens générés pour éviter un dépassement de mémoire
        generated_ids = model.generate(
            **model_inputs,
            max_new_tokens=512,  # Limitation à 512 tokens pour la réponse
            temperature=0.6,  # Ajustement pour rendre les réponses plus variées
            top_p=0.95  # Nucleus sampling pour améliorer la cohérence
        )
    except Exception as e:
        print(f"Erreur lors de la génération : {e}")
        print("Désolé, une erreur s'est produite. Réessayez avec une autre question.")
        continue  # Passe au prochain prompt sans arrêter le programme

    # Fin de la mesure du temps de génération
    end_time = time.time()
    print(f"Temps de génération : {end_time - start_time:.2f} secondes")

    # Extraction uniquement des tokens générés (sans répéter l'entrée utilisateur)
    generated_ids = [
        output_ids[len(input_ids):] for input_ids, output_ids in zip(model_inputs.input_ids, generated_ids)
    ]

    # Décodage des tokens générés pour obtenir une réponse lisible
    response = tokenizer.batch_decode(generated_ids, skip_special_tokens=True)[0]

    # Affichage de la réponse générée par Qwen
    print("Réponse de Qwen :")
    print(response)
    print("-" * 50)  # Ligne de séparation pour une meilleure lisibilité


