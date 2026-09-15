import os
from openai import OpenAI
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")



client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=OPENROUTER_API_KEY,
)

chat_history = [
    {"role": "system", "content": "أنت 'مساعد ميندورا الذكي' (Mindora AI)، رفيق ومرشد داعم لأولياء أمور أطفال متلازمة داون. مهمتك تقديم إرشادات ونصائح تدريبية وتأهيلية مبسطة بأسلوب عربي ولهجة مصرية ودودة ومحفزة لولي الأمر. ركز على التحفيز الحركي والنطق والتواصل والاستقلالية اليومية. الردود إرشادية وتوعوية وليست تشخيصاً طبياً أو وصفة علاجية ولا تغني عن الاستشارة الطبية السريرية. في حال استفسار ولي الأمر عن أدوية أو أعراض مرضية حادة أو حالات طارئة، انصحه بلطف بالتواصل الفوري مع الطبيب المختص أو مراجعة العيادة."}
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