import cv2
import mediapipe as mp
import math
import numpy as np
import random
import time

def draw_star(img, center, radius, color):
    x, y = center
    points = []
    for i in range(10):
        r = radius if i % 2 == 0 else radius // 2.5
        angle = i * (math.pi / 5) - (math.pi / 2)
        pt_x = int(x + r * math.cos(angle))
        pt_y = int(y + r * math.sin(angle))
        points.append([pt_x, pt_y])
    
    pts = np.array(points, np.int32).reshape((-1, 1, 2))
    cv2.fillPoly(img, [pts], color)

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(min_detection_confidence=0.7, min_tracking_confidence=0.7)
mp_draw = mp.solutions.drawing_utils

cap = cv2.VideoCapture(0)

level = 1
max_levels = 5
target_radius = 80
target_x = random.randint(150, 450)
target_y = random.randint(150, 350)

level_start_time = time.time()
level_passed_time = 0
therapy_report = []

while cap.isOpened():
    success, image = cap.read()
    if not success:
        break

    image = cv2.flip(image, 1)
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = hands.process(image_rgb)
    
    current_time = time.time()
    
    if level <= max_levels:
        cv2.putText(image, f"Level: {level}/5", (20, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)
        star_color = (0, 0, 255)
        
        if results.multi_hand_landmarks and current_time - level_passed_time > 1.5:
            for hand_landmarks in results.multi_hand_landmarks:
                mp_draw.draw_landmarks(image, hand_landmarks, mp_hands.HAND_CONNECTIONS)
                
                palm_center = hand_landmarks.landmark[9]
                h, w, c = image.shape
                cx, cy = int(palm_center.x * w), int(palm_center.y * h)
                
                distance = math.hypot(cx - target_x, cy - target_y)
                
                if distance < target_radius + 30:
                    time_taken = round(current_time - level_start_time, 2)
                    therapy_report.append({"Level": level, "Time (Seconds)": time_taken})
                    
                    star_color = (0, 255, 0)
                    level += 1
                    
                    if level <= max_levels:
                        target_radius = max(30, target_radius - 12)
                        target_x = random.randint(100, 500)
                        target_y = random.randint(100, 400)
                        level_start_time = time.time()
                        
                    level_passed_time = time.time()

        if level <= max_levels:
            draw_star(image, (target_x, target_y), target_radius, star_color)

        if current_time - level_passed_time <= 1.5 and 1 < level <= max_levels + 1:
            cv2.putText(image, "Level Passed!", (150, 240), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 0), 3)

    else:
        cv2.putText(image, "Therapy Completed!", (100, 240), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 0), 3)
        if current_time - level_passed_time > 3:
            break

    cv2.imshow("Mindora Motor Therapy Demo", image)

    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()

print("\n--- تقرير الجلسة الحركية (Therapy Report) ---")
total_time = 0
for data in therapy_report:
    print(f"المستوى {data['Level']}: استغرق {data['Time (Seconds)']} ثانية")
    total_time += data['Time (Seconds)']

print(f"\nإجمالي وقت الجلسة: {round(total_time, 2)} ثانية")
print(f"متوسط سرعة الاستجابة: {round(total_time/max_levels, 2)} ثانية/مستوى")