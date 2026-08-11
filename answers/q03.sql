SET TIME ZONE 'UTC';
SELECT produto_id,sku,nome,data_descontinuacao FROM produtos WHERE data_descontinuacao IS NOT NULL ORDER BY data_descontinuacao,sku;
