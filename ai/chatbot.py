from openai import OpenAI

OPENROUTER_API_KEY = "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"

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=OPENROUTER_API_KEY,
)

chat_history = [
    {"role": "system", "content": "أنت مساعد ذكي مخصص لأطباء وأخصائيين تأهيل أطفال متلازمة داون في تطبيق Mindora. مهمتك الرد باقتراح طبي مختصر ومفيد باللغة العربية العامية المصرية."}
]

def generate_chatbot_response(user_message: str) -> str:
    chat_history.append({"role": "user", "content": user_message})

    try:
        response = client.chat.completions.create(
            model="meta-llama/llama-3.1-8b-instruct", 
            messages=chat_history,
            temperature=0.7
        )
        
        bot_reply = response.choices[0].message.content
        
        chat_history.append({"role": "assistant", "content": bot_reply})
        
        return bot_reply
        
    except Exception as e:
        chat_history.pop()
        return f"حصلت مشكلة في الاتصال: {str(e)}"

if __name__ == "__main__":
    print("chatbot is ready)\n")
    
    while True:
        user_input = input("أنت: ")
        
        if user_input.strip() == 'خروج':
            break
            
        result = generate_chatbot_response(user_input)
        print(f"\nالبوت: {result}\n")