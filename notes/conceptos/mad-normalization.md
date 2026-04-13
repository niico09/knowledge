# MAD Normalization (Median Absolute Deviation)

## Definición

Métrica de dispersión robusta: `MAD = median(|X - median(X)|)`. A diferencia de desviación estándar, es robusta a outliers.

## Uso en Latent Briefing

En lugar de seleccionar top-k tokens fijo, se usa MAD normalization para thresholding:

```
Keep position i si: position_scores[i] > median + threshold · MAD
```

## Por qué robusto

- **Std normal**: Sensible a valores extremos (un outlier distorsiona)
- **MAD**: El outlier contribuye poco porque se usa mediana, no media

## Relación con Attention Matching

MAD normalization es la técnica de thresholding usada en [[attention-matching]] (y por extensión [[latent-briefing]]) para determinar cuáles tokens preservar en el KV cache compacto.

## Referencia

- Zweiger et al., 2026 — arXiv:2602.16284
