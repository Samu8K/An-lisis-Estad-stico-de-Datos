# ============================================================
# Extensión multivariada: Hotelling, PCA, LDA, correlación canónica,
# K-means (silueta) y análisis de correspondencias.
# Sin paquetes extra: usa stats, MASS y cluster (vienen con R).
# NO ha sido ejecutado por el asistente: corre y revisa la salida.
# ============================================================
library(MASS); library(cluster)
set.seed(2026)

# --- 1. Lectura (ajusta la ruta si hace falta) ---
f <- list.files(pattern = "bank.?data.*\\.csv$", recursive = TRUE, full.names = TRUE)
d <- read.csv(if (length(f)) f[1] else file.choose())
print(names(d))

# --- 2. AJUSTA ESTOS NOMBRES a las columnas que imprimió names(d) ---
col_age <- "Age"; col_sal <- "Salary"; col_eng <- "Engagement_Score"
col_city <- "City"; col_gen <- "Gender"; col_tier <- "Subscription_Tier"
col_act <- "Is_Active"

x <- data.frame(age = d[[col_age]], sal = d[[col_sal]], eng = d[[col_eng]],
                city = factor(d[[col_city]]), gen = factor(d[[col_gen]]),
                tier = factor(d[[col_tier]]),
                act = factor(as.character(d[[col_act]])))
x <- x[complete.cases(x), ]
num <- scale(x[, c("age", "sal", "eng")])
cat("Casos completos:", nrow(x), "\n")

# --- 3. Hotelling T² (activos vs. inactivos) ---
m <- manova(as.matrix(x[, c("age", "sal", "eng")]) ~ x$act)
cat("\n== Hotelling (MANOVA 2 grupos, test Hotelling-Lawley) ==\n")
print(summary(m, test = "Hotelling-Lawley"))

# --- 4. PCA ---
p <- prcomp(num)
cat("\n== PCA: proporción de varianza por componente ==\n")
print(round(summary(p)$importance, 4))

# --- 5. Discriminante lineal (70/30) ---
idx <- sample(nrow(x), 0.7 * nrow(x))
tr <- x[idx, ]; te <- x[-idx, ]
l <- lda(act ~ age + sal + eng, data = tr)
pr <- predict(l, te)$class
cat("\n== LDA ==\nExactitud:", round(mean(pr == te$act), 4),
    "| Línea base (clase mayoritaria):", round(max(prop.table(table(te$act))), 4), "\n")
print(table(Real = te$act, Predicho = pr))

# --- 6. Correlación canónica: (edad, salario, engagement) vs. dummies de categóricas ---
Z <- model.matrix(~ city + gen + tier + act, data = x)[, -1]
cc <- cancor(num, Z)
cat("\n== Correlaciones canónicas ==\n"); print(round(cc$cor, 4))

# --- 7. K-means con silueta (submuestra de 5.000 por costo O(n²)) ---
s <- sample(nrow(num), 5000)
cat("\n== K-means: silueta media por k ==\n")
for (k in 2:5) {
  km <- kmeans(num[s, ], centers = k, nstart = 10)
  cat("k =", k, " silueta =", round(mean(silhouette(km$cluster, dist(num[s, ]))[, 3]), 4), "\n")
}

# --- 8. Análisis de correspondencias: ciudad x actividad y suscripción x actividad ---
for (v in c("city", "tier")) {
  tb <- table(x[[v]], x$act)
  ca <- corresp(tb, nf = 1)
  cat("\n== Correspondencias:", v, "x actividad ==\n")
  cat("Correlación canónica (1ª dimensión):", round(ca$cor, 5),
      "| Inercia total ≈", round(ca$cor^2, 8), "\n")
  print(chisq.test(tb))
}
cat("\nListo. Guarda la salida completa y pásasela al asistente.\n")
