from openai import OpenAI
from ollama import Client

import config

def chat(backend : str, model : str, messages : list) -> str:
    if backend == "openai":
        client = OpenAI(api_key=config.OPENAI_API_KEY)
        
        response = client.responses.create(
            model=model,
            instructions=messages[0],
            input=messages[1]
        )

        return response.output_text
    else:
        client = Client()
        
        messages_formatted = [
            {"role": "system", "content": messages[0]},
            {"role": "user", "content": messages[1]}
        ]
        
        response = client.chat(model=model, messages=messages_formatted).message.content
        
        return response