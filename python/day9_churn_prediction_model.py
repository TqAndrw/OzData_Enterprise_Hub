#Xây dựng một mô hình Machine Learning dự đoán chính xác những khách hàng sắp Churn
#trong 30 ngày tới để hệ thống tự động gửi Voucher níu chân

#Architectural Mindset: Không dùng Accuracy để đánh giá mô hình ML 
#Churn = Bài toán mất cân bằng dữ liệu vì Số người churn < số người ở lại
#Ví dụ: Nếu dự đoán 100% KH ko churn => Accuracy = 90% nma mô hình hoàn toàn vô dụng

#Thuật toán: Tree-based: Random Forest -> Xử lý tốt những mối quan hệ phi tuyến tính (non linear)
#của các chỉ số RFM

#Train - Test Split: Dùng kĩ thuật stratified sampling để 
# đảm bảo tỷ lệ Churn/Non Churn ở train và test là giống hệt nhau

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report

#1. Pandas: Tách biến độc lập X và biến mục tiêu Y
# Giả sử DataFrame df_features được làm sạch bằng sql ở tầng gold layer và nạp vào python
# => Việc đầu tiên là tách nó ra 
df_features = pd.read_sql()

X = df_features.drop('Churn_Flag', axis = 1) #X (features): lấy tất cả các cột trừ cột mục tiêu
#Syntax: .drop('Tên cột', axis =1) = dùng để vứt bỏ 1 dữ liệu nào đó khỏi bảng
# axis = 1 => Cột , axis = 0 => Hàng

y = df_features['Churn_Flag']
#df['tên côt'] = cách trích xuất riêng 1 cột ra khỏi bảng => Y là target của mô hình

#2. Scikit-learn: train_test_split: kĩ thuật stratified sampling
# Chia dữ liệu ngẫu nhiên thì có thể ko có KH nào churn ở tập test vì số lượng churn ít
# => Dùng tham số stratify ép hệ thống giữ nguyên tỷ lệ Churn/Non-churn ở cả 2 tập train và test
X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size = 0.2, #20% dữ liệu để test
    stratify = y, #Bắt buộc cho Imbalanced Data (Churn là 1 ví dụ)
    random_state = 42 #Khóa seed để lần nào chạy lại kết quả cũng giống nhau
)
#X,y = tập dữ liệu gốc ở bước 1 với pandas
#test_size = 0.2 => Chỉ định chia 20% test, 80%  train
#stratify=y => Nếu tỷ lệ Churn/Ở lại ở tập gốc y = 10/90 thì hàm này ép tập Train và Test đều phải có chính xác tỷ lệ 10/90 đó
#random_state=42 => Máy tính ko có ngẫu nhiên mà dùng công thức toán để xáo trộn => Nếu vậy thì phải cố định random_state lại để lần nào chạy thì cách xáo trộn đều giống nhau => kết quả y hệt nhau => tái lập và verify lại kết quả của nhau

#3. Scikit-learn(pipeline & thuật toán): Chống data leakage
#Data leakage: rò rỉ dữ liệu xảy ra khi chuẩn hóa (scale) toàn bộ dữ liệu trước khi chia Train/Test
#Khi đó tập Train đã vô tình "nhìn thấy" thông tin của tập Test
#=> Gộp bộ chuản hóa và mô hình vào 1 pipeline

#Pipeline nhận vào một list các tuples: ('tên bước', hàm thực thi)
model_pipeline = Pipeline([
    ('scaler', StandardScaler()),
    #Random Forest xử lý imbalanced data bằng class_weight = 'balanced'
    ('rf_model', RandomForestClassifier(class_weight = 'balanced', random_state = 42))
])
#LIST - DẤU NGOẶC [] VÀ TUPLE - DẤU NGOẶC ('Tên bước', hàm thực thi)
#StandardScaler(): hàm này sẽ biến đổi các cột dữ liệu (ví dụ thu nhập 100k$ và tuổi 25) về cùng 1 thang đo (mean = 0, standard deviation = 1) để thuật toán khôg bị lêhcj trọng tâm vào các con số lớn
#class_weight ='balanced': Thuật toán Random Forest thôgn thường sẽ lười biếng và cứ đoán khách hàng 'Ở lại' viof nhóm này chiếm đa sớ
#=> tham số này ra lệnh "Nhóm nào ít người hơn (Churn), thì phạt mô hình thật nặng nếu nó đoán sai => mô hình tập trung bắt kh churn hơn"

#Lưu ý: Random Forest ko nhạy cảm với việc scale dữ liệu như Log Regress hay SVM
# Nma việc đưa StandardScaler vào pipeline luôn là enterprise best practice để sau dễ dàng thay đổi thuật toán

#4. Các hàm thực thi(fit, predict, classification_report) => Training predic & evaluation
#Mô hình ML cần được "học" = fit, "đoán" = predict và cuối cùng là ra báo cáo
#Trong báo cáo, stakeholders tập trung vào Recall(bắt trúng đc bnh người thực sự sắp churn) và Precision (dự đoán churn thì đúng được bnh %)

model_pipeline.fit(X_train, y_train) #1. Bắt mô hình học trên tập Train
#model_pipeline.fit = bắt pipeline thực thi, đầu tiên, nó sẽ scale X_train, sau đó mang X_train và đáp án y_train nhét vào mô hình Random Forest để tìm ra quy luật(Learning)
y_pred = model_pipeline.predict(X_test) #2. Bắt mô hình dự đoán thử trên tập Test
#Sau khi fit xong, đưa X_test vào để kiểm tra. Mô hình sẽ dùng quy luật vừa học để đưa ra các đáp án dự doán lưu vào biến y_pred
print(classification_report(y_test, y_pred)) #3. In báo cáo đánh giá
#classification_report(y_test, y_pred) => so sánh đáp án thực tế là y_test với đáp án mô hình y_pred để tính toán điểm số
