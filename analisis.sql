/*
Empezaremos analizando en total contamos con 6 tablas, se considerara como la tabla "sale" como tabla de hecho
*/

SELECT top 5 * FROM [dbo].[Countries]

SELECT top 5 * FROM [dbo].[Customer]

SELECT top 5 * FROM [dbo].[orden_status]

SELECT top 5 * FROM [dbo].[Products]

SELECT top 5 * FROM [dbo].[Region]

SELECT top 5 * FROM [dbo].[Sales]

/*
Se procede a sacar los numeros de caracteres para las columnas de texto
*/



SELECT MAX(LEN(country)) FROM [dbo].[Countries]





SELECT MAX(LEN(customer_name)) FROM [dbo].[Customer]



SELECT MAX(LEN(description)) FROM [dbo].[orden_status]



SELECT MAX(LEN(category)) FROM [dbo].[Products]

SELECT MAX(LEN(product_name)) FROM [dbo].[Products]



SELECT MAX(LEN(continent)) FROM [dbo].[Region]

/*
Analisando relacion de datos por un usuario aleatoreo

En este analisis procedemos a ver que el id\_region y id\_continent no tienen congruencia, ya que al hacer el join de las tablas no trae congruencia de de los paises con continentes.

\- Se considerara id\_region como la region donde se creo el usuario

\- Se considera id\_country como el pais donde reside el cliente junto con su continente
*/

SELECT * FROM Customer WHERE customer_name = 'Olivia Smith'

SELECT * FROM Countries

SELECT * FROM Region

/*
Se procede a crear una vista para simplificar el analisis de datos
*/

CREATE VIEW VIZ_SALES 

AS

SELECT 

       SL.[id_sale]

      ,SL.[date_sale]

      ,CS.[date_creation]

      ,CS.[customer_name]

      ,RG.[continent] AS continent_created

      ,RGV.continent 

      ,CTS.[country] 

      ,PD.[product_name]

      ,PD.[category]

      ,OST.[description]

      ,PD.[unit_price]

      ,SL.[quantity]

      

FROM [dbo].[Sales] AS SL



LEFT JOIN Customer AS CS ON SL.id_customer = CS.id_customer

LEFT JOIN Region AS RG ON CS.id_region = RG.id_region



LEFT JOIN Countries AS CTS ON CS.id_country  = CTS.id_country

LEFT JOIN Region AS RGV ON CTS.id_region = RGV.id_region

LEFT JOIN Products AS PD ON SL.id_product =  PD.id_product 

LEFT JOIN orden_status AS OST ON SL.id_status = OST.id_status





/*
Validar la view que se creo
*/

SELECT TOP 5 * FROM VIZ_SALES

/*
¿Cuál es la distribución geográfica de las ventas de productos Nike durante el último trimestre del año <span style="color: #09885a;">2023</span>?
*/

SELECT 

    country

    ,SUM(unit_price) * SUM(quantity) AS Ventas

FROM VIZ_SALES 

GROUP BY 

    country



/*
¿Cuál es el producto más vendido por país y por mes en el 2023?
*/

WITH TGNR AS (

    SELECT 

        MONTH(date_sale) AS [Numero mes],

        country,

        product_name,

        SUM(quantity) AS [Unidades vendidas],

        SUM(unit_price * quantity) AS VentasTotales,

        ROW_NUMBER() OVER (PARTITION BY MONTH(date_sale),country ORDER BY SUM(unit_price * quantity) DESC) AS Rank

    FROM VIZ_SALES

    GROUP BY 

        product_name,

        MONTH(date_sale),

        country

)

SELECT 

    [Numero mes],

    country,

    product_name,

    VentasTotales AS Ventas,

    [Unidades vendidas]

FROM TGNR

WHERE Rank = 1

ORDER BY [Numero mes]



/*
¿Cuál es el cliente con más compras por país y por mes en el 2023?
*/

WITH VentasPorMes AS (

    SELECT 

        MONTH(date_sale) AS [Numero mes],

        country,

        customer_name,

        SUM(unit_price * quantity) AS VentasTotales,

        ROW_NUMBER() OVER (PARTITION BY MONTH(date_sale), country ORDER BY SUM(unit_price * quantity) DESC) AS Rank

    FROM VIZ_SALES

    GROUP BY 

        country,

        MONTH(date_sale),

        customer_name

)

SELECT 

    [Numero mes],

    country,

    customer_name,

    VentasTotales AS Ventas

FROM VentasPorMes

WHERE Rank = 1

ORDER BY [Numero mes],country

/*
¿Cuál es el promedio de ventas por región o país durante el último trimestre del año 2023?
*/

WITH TGEN AS (

    SELECT 

        continent,

        country,

        unit_price * quantity AS VentaTotal

    FROM VIZ_SALES

    WHERE YEAR(date_sale) = 2023

      AND MONTH(date_sale) >= 10 

      AND MONTH(date_sale) <= 12

)



SELECT

    continent,

    country,

    SUM(VentaTotal) AS VentalTotal,

    AVG(VentaTotal) AS PromedioVentas

FROM TGEN

GROUP BY 

    continent,

    country

ORDER BY 

    continent,

    country;





/*
¿Cuál es el producto más vendido durante el último trimestre del año 2023?
*/

WITH TGEN AS (

    SELECT 

        product_name,

        SUM(unit_price * quantity) AS VentaTotal,

        ROW_NUMBER() OVER (ORDER BY SUM(unit_price * quantity) DESC) AS Rank

    FROM VIZ_SALES

    WHERE YEAR(date_sale) = 2023

      AND MONTH(date_sale) >= 10 -- Último trimestre: meses 10, 11 y 12

      AND MONTH(date_sale) <= 12

    GROUP BY 

        product_name

)



SELECT

    product_name,

    VentaTotal

FROM TGEN

WHERE Rank = 1

ORDER BY 

    VentaTotal DESC

/*
¿Cuál es el cliente con más compras durante el último trimestre del año 2023?
*/

WITH TGEN AS (

    SELECT 

        customer_name,

        SUM(unit_price * quantity) AS VentaTotal,

        ROW_NUMBER() OVER (ORDER BY SUM(unit_price * quantity) DESC) AS Rank

    FROM VIZ_SALES

    WHERE YEAR(date_sale) = 2023

      AND MONTH(date_sale) >= 10 -- Último trimestre: meses 10, 11 y 12

      AND MONTH(date_sale) <= 12

    GROUP BY 

        customer_name

)



SELECT

    customer_name,

    VentaTotal

FROM TGEN

WHERE Rank = 1

ORDER BY 

    VentaTotal DESC

/*
¿Cuál es el promedio de cantidad de productos comprados por cliente?
*/

    SELECT 

        customer_name,

        AVG(quantity) AS [%Promedio],

        SUM(quantity) AS [Total_unidades]

    FROM VIZ_SALES

    WHERE YEAR(date_sale) = 2023

      AND MONTH(date_sale) >= 10 -- Último trimestre: meses 10, 11 y 12

      AND MONTH(date_sale) <= 12

    GROUP BY 

        customer_name

    ORDER BY 

        AVG(quantity) DESC

/*
¿Existe alguna tendencia de ventas en función del día de la semana?
*/

WITH TGNR AS 

            (SELECT

                DiaSemana,

                ISNULL([10], 0) AS Octubre,

                ISNULL([11], 0) AS Noviembre,

                ISNULL([12], 0) AS Diciembre

            FROM (

                SELECT

                    DATEPART(dw, date_sale) AS DiaSemana,

                    MONTH(date_sale) AS Mes,

                    SUM(quantity * unit_price) AS TotalVenta

                FROM VIZ_SALES

                GROUP BY

                    DATEPART(dw, date_sale),

                    MONTH(date_sale)

            ) AS SalesPerDayOfMonth

            PIVOT (

                SUM(TotalVenta)

                FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])

            ) AS PivotTable

            )

SELECT 

Octubre,

(Noviembre/Octubre) -1 AS [%OCTvsNOV],

Noviembre,

(Diciembre/Noviembre) -1 AS [%NOVvsDIV],

Diciembre

FROM TGNR

/*
¿Qué porcentaje de las ventas se ve afectado por aquellas órdenes devueltas y canceladas?
*/

WITH TGEN AS (

    SELECT

        SUM(unit_price * quantity) AS TotalVentas

    FROM VIZ_SALES

),

TGEN_DESC AS (

    SELECT

        CASE description

            WHEN 'Cancelled' THEN 'Canceled/Returned'

            WHEN 'Returned' THEN 'Canceled/Returned'

        ELSE description

        END GroupDescription,

        description,

        SUM(unit_price * quantity) AS Ventas

    FROM VIZ_SALES

    GROUP BY description

)

SELECT 

    TD.GroupDescription,

    TD.description,

    TD.Ventas,

    (TD.Ventas * 1.0 / TG.TotalVentas) AS [%Share],

    (SUM(TD.Ventas) OVER(PARTITION BY GroupDescription) * 1.0 / TG.TotalVentas) AS [%SharebyGroup]

    

FROM TGEN_DESC TD, TGEN TG





/*
¿Cuántos productos y clientes no han tenido durante el último trimestre del año 2023?
*/

SELECT 

    id_sale

    ,CS.*

FROM Sales AS SL

FULL OUTER JOIN Customer AS CS ON SL.id_customer = CS.id_customer

WHERE id_sale is null



-- LEFT JOIN Products AS PD ON SL.id_product =  PD.id_product 

-- LEFT JOIN orden_status AS OST ON SL.id_status = OST.id_status

SELECT 

    id_sale

    ,PD.*

FROM Sales AS SL

FULL OUTER JOIN Products AS PD ON SL.id_product =  PD.id_product

WHERE id_sale is null