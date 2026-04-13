# Ridge Regression

## Definición

Técnica de regresión con regularización L2. Agrega término λ||w||² a la función de costo para evitar overfitting cuando hay multicolinealidad o muchas features.

## Solución cerrada

```
β = (XᵀX + λI)⁻¹Xᵀy
```

Donde λI (matriz identidad multiplicada por λ) es el término de regularización.

## Uso en Attention Matching

En el paso 3 del algoritmo AM (C2 via ridge regression), se reconstruyen los value vectors:

```
C2 = (XᵀX + λI)⁻¹XᵀY
```

Donde:
- X = softmax matrix compacta
- Y = attention output original
- λ = parámetro de regularización

Esto reconstruye value vectors que preservan la computación de atención original a pesar de haber descartado keys/values redundantes.

## Relación con KV Cache

En [[attention-matching]], ridge regression es el mecanismo matemático para comprimir values mientras se preserva la información útil para el modelo. Ver [[kv-cache]] y [[attention-matching]].

## Referencia

- Zweiger et al., 2026 — arXiv:2602.16284
