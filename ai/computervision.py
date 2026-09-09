import cv2
import mediapipe as mp
import math

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(min_detection_confidence=0.7, min_tracking_confidence=0.7)
mp_draw = mp.solutions.drawing_utils

cap = cv2.VideoCapture(0)

while cap.isOpened():
    success, image = cap.read()
    if not success:
        break

    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = hands.process(image_rgb)

    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            mp_draw.draw_landmarks(image, hand_landmarks, mp_hands.HAND_CONNECTIONS)

            thumb_tip = hand_landmarks.landmark[4]
            index_tip = hand_landmarks.landmark[8]

            h, w, c = image.shape
            cx1, cy1 = int(thumb_tip.x * w), int(thumb_tip.y * h)
            cx2, cy2 = int(index_tip.x * w), int(index_tip.y * h)

            distance = math.hypot(cx2 - cx1, cy2 - cy1)

            if distance < 50:
                cv2.circle(image, (cx1, cy1), 15, (0, 255, 0), cv2.FILLED)
                cv2.putText(image, "Target Hit! Score +1", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
                print("Target Hit! Score +1")

    cv2.imshow("Mindora Motor Therapy Demo", image)

    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()