#install.packages("tidyverse")
#install.packages("caret")     # للتقسيم والتقييم
#install.packages("Metrics",dependencies = TRUE)   # لحساب MAE بسهولة
#install.packages("randomForest")
#install.packages("xgboost")

# تحميل المكتبات
library(tidyverse)
library(caret)
library(tidyr)
library(Metrics)
library(lmtest)
library(randomForest)
library(xgboost)
library(corrplot)

#


# قراءة البيانات
df<- read.csv("insurance.csv")
head(df)
str(df)
summary(df)

# تحويل المتغيرات إلى متغيرات فئوية
df$sex <- as.factor(df$sex)
df$smoker <- as.factor(df$smoker)
df$region <- as.factor(df$region)


#####
# توزيع التكلفة
ggplot(df, aes(x = charges)) + geom_histogram()

# علاقة كل متغير بالتكلفة
ggplot(df, aes(x = age, y = charges, color = smoker)) + geom_point()
ggplot(df, aes(x = bmi, y = charges, color = smoker)) + geom_point()
ggplot(df, aes(x = sex, y = charges, color = smoker)) + geom_point()
ggplot(df, aes(x = children, y = charges, color = smoker)) + geom_point()


# مصفوفة الارتباط
cor(df[, c("age","bmi","children","charges")])


df$bmi_cat <- cut(df$bmi, 
                  breaks = c(0, 18.5, 25, 30, Inf),
                  labels = c("نحيف", "طبيعي", "زيادة وزن", "سمنة"))

# تصنيف العمر إلى فئات
df$age_cat <- cut(df$age,
                  breaks = c(0, 30, 45, Inf),
                  labels = c("شاب", "متوسط", "كبير"))


df$bmi30 <- ifelse(df$bmi >= 30 & df$smoker == "yes", 1, 0)


##### 
set.seed(123)

trainIndex <- createDataPartition(df$charges, p = 0.8, list = FALSE)
train <- df[trainIndex, ]
test  <- df[-trainIndex, ]


# Linear Model

model_linear <- lm(charges ~ age + bmi + children + smoker + sex + region, data = train)
summary(model_linear)

pred_linear <- predict(model_linear, newdata = test)

mae_linear <- mae(test$charges, pred_linear)
rmse_linear <- rmse(test$charges, pred_linear)

mae_linear
rmse_linear

plot(model_linear$fitted.values, resid(model_linear),
     xlab = "Fitted values",
     ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")

bptest(model_linear)
# Linear 2
model_linear2 <- lm(charges ~ age + bmi + smoker + bmi:smoker + I(age^2), data = train)
pred_linear2 <- predict(model_linear2, newdata = test)

mae(test$charges, pred_linear2)
rmse(test$charges, pred_linear2)

plot(model_linear2$fitted.values, resid(model_linear2),
     xlab = "Fitted values",
     ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")

bptest(model_linear2)

#   Gamma model 


model_gamma2 <- glm(charges ~ age + bmi + smoker + bmi:smoker + I(age^2),
                    family = Gamma(link = "log"),
                    data = train)
pred_gamma2 <- predict(model_gamma2, newdata = test, type = "response")
mae(test$charges, pred_gamma2)
rmse(test$charges, pred_gamma2)

plot(model_gamma2$fitted.values, resid(model_gamma2),
     xlab = "Fitted values",
     ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")

bptest(model_gamma2)

# Linear 3

model_linear3 <- lm(charges ~ age + I(age^2) + bmi + I(bmi^2) +
                        smoker + bmi:smoker + children,
                    data = train)

pred_linear3 <- predict(model_linear3, newdata = test)

mae(test$charges, pred_linear3)
rmse(test$charges, pred_linear3)

plot(model_linear3$fitted.values, resid(model_linear3),
     xlab = "Fitted values",
     ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")

bptest(model_linear3)


# Linear 4

model_linear4 <- lm(charges ~ age + I(age^2) + bmi + I(bmi^2) +
                        smoker + bmi:smoker + bmi30 + children,
                    data = train)

pred_linear4 <- predict(model_linear4, newdata = test)
mae(test$charges, pred_linear4)
rmse(test$charges, pred_linear4)


plot(model_linear4$fitted.values, resid(model_linear4),
     xlab = "Fitted values",
     ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")

bptest(model_linear4)
saveRDS(model_linear4, "model_linear4.rds")


# Log Model

model_log <- lm(log(charges) ~ age + I(age^2) + bmi + I(bmi^2) +
                    smoker + bmi:smoker + children,
                data = train)
pred_log <- exp(predict(model_log, newdata = test))
mae(test$charges, pred_log)
rmse(test$charges, pred_log)

plot(model_log$fitted.values, resid(model_log),
     xlab = "Fitted values",
     ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")

bptest(model_log)


model_log2 <- lm(log(charges) ~ age + I(age^2) + bmi + I(bmi^2) +
                     smoker + bmi:smoker + bmi30 + children,
                 data = train)

pred_log2 <- exp(predict(model_log2, newdata = test))
mae(test$charges, pred_log2)
rmse(test$charges, pred_log2)


plot(model_log2$fitted.values, resid(model_log2),
     xlab = "Fitted values",
     ylab = "Residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red")

bptest(model_log2)



model_RandomForest <- randomForest(charges ~ age + bmi + children + smoker + sex + region + bmi30,
                                   data = train,
                                   ntree = 1000)


pred_RandomForest <- predict(model_RandomForest, newdata = test)
mae(test$charges, pred_RandomForest)
rmse(test$charges, pred_RandomForest)



# البواقي لـ Random Forest
pred_train_RF <- predict(model_RandomForest, newdata = train)
residuals_RF  <- train$charges - pred_train_RF

plot(pred_train_RF, residuals_RF,
     xlab = "Fitted values",
     ylab = "Residuals",
     main = "Residuals vs Fitted - Random Forest")
abline(h = 0, col = "red")



###

# تحضير البيانات لـ XGBoost
train_matrix <- model.matrix(charges ~ age + bmi + children + 
                                 smoker + sex + region + bmi30, 
                             data = train)[, -1]

test_matrix <- model.matrix(charges ~ age + bmi + children + 
                                smoker + sex + region + bmi30, 
                            data = test)[, -1]

# تحويل إلى صيغة xgboost
dtrain <- xgb.DMatrix(data = train_matrix, label = train$charges)
dtest  <- xgb.DMatrix(data = test_matrix,  label = test$charges)
model_xgb <- xgb.train(data = dtrain,
                       nrounds = 500,
                       params = list(
                           learning_rate = 0.05,
                           max_depth = 6,
                           objective = "reg:squarederror"
                       ))

pred_xgb <- predict(model_xgb, dtest)
mae(test$charges, pred_xgb)
rmse(test$charges, pred_xgb)





##


results <- data.frame(
    Model = c("Linear1", "Linear2", "Gamma", "Linear3", "Linear4", "Log","Log2","RF","XGP"),
    MAE   = c(mae_linear, mae(test$charges, pred_linear2), 
              mae(test$charges, pred_gamma2), mae(test$charges, pred_linear3),
              mae(test$charges, pred_linear4), mae(test$charges, pred_log),mae(test$charges, pred_log2),
              mae(test$charges, pred_RandomForest),  mae(test$charges, pred_xgb)),
    RMSE  = c(rmse_linear, rmse(test$charges, pred_linear2),
              rmse(test$charges, pred_gamma2), rmse(test$charges, pred_linear3),
              rmse(test$charges, pred_linear4), rmse(test$charges, pred_log),
              rmse(test$charges, pred_log2),rmse(test$charges, pred_RandomForest),rmse(test$charges, pred_xgb)

    )
)
print(results)


####

# حساب حدود الفئات
q33 <- quantile(df$charges, 0.33)
q66 <- quantile(df$charges, 0.66)

# إنشاء عمود الخطر على df كاملاً قبل التقسيم
df$risk <- cut(df$charges,
               breaks = c(-Inf, q33, q66, Inf),
               labels = c("Low", "Medium", "High"))

df$risk <- as.factor(df$risk)
saveRDS(c(q33, q66), "risk_quantiles.rds")

set.seed(123)
trainIndex2 <- createDataPartition(df$risk, p = 0.8, list = FALSE)
train2 <- df[trainIndex2, ]
test2  <- df[-trainIndex2, ]

model_RF_class <- randomForest(risk ~ age + bmi + children + 
                                   smoker + sex + region + bmi30,
                               data = train2,
                               ntree = 1000)

pred_RF_class <- predict(model_RF_class, newdata = test2)

# التقييم
confusionMatrix(pred_RF_class, test2$risk)
saveRDS(model_RF_class, "model_RF_class.rds")


###

# تحويل الفئات إلى أرقام (XGBoost يحتاج 0، 1، 2)
train2$risk_num <- as.numeric(train2$risk) - 1
test2$risk_num  <- as.numeric(test2$risk) - 1

train_matrix2 <- model.matrix(risk ~ age + bmi + children + 
                                  smoker + sex + region + bmi30,
                              data = train2)[, -1]

test_matrix2 <- model.matrix(risk ~ age + bmi + children + 
                                 smoker + sex + region + bmi30,
                             data = test2)[, -1]

dtrain2 <- xgb.DMatrix(data = train_matrix2, label = train2$risk_num)
dtest2  <- xgb.DMatrix(data = test_matrix2,  label = test2$risk_num)

model_xgb_class <- xgb.train(data = dtrain2,
                             nrounds = 500,
                             params = list(
                                 learning_rate = 0.05,
                                 max_depth = 6,
                                 objective = "multi:softmax",
                                 num_class = 3
                             ))

pred_xgb_class <- predict(model_xgb_class, dtest2)

# تحويل الأرقام إلى فئات للمقارنة
pred_xgb_class <- factor(pred_xgb_class, 
                         levels = c(0,1,2),
                         labels = c("Low","Medium","High"))

confusionMatrix(pred_xgb_class, test2$risk)



####

# استخراج أهمية المتغيرات
importance_RF <- importance(model_RF_class)
varImpPlot(model_RF_class, 
           main = "Feature Importance - Random Forest")

##

importance_XGB <- xgb.importance(model = model_xgb)
xgb.plot.importance(importance_XGB,
                    main = "Feature Importance - XGBoost")


###

# معاملات النموذج مرتبة حسب الأهمية
coef_df <- data.frame(
    Variable = names(coef(model_linear4)),
    Coefficient = abs(coef(model_linear4))
) %>%
    arrange(desc(Coefficient)) %>%
    filter(Variable != "(Intercept)")

ggplot(coef_df, aes(x = reorder(Variable, Coefficient), y = Coefficient)) +
    geom_bar(stat = "identity", fill = "steelblue") +
    coord_flip() +
    labs(title = "Feature Importance - Linear4",
         x = "المتغير", y = "الأهمية")