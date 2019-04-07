-- ilosc wnioskow z analiza prawna w danym roku

SELECT to_char(data_wyslania_sad, 'YYYY') AS rok, COUNT(id) FROM analiza_prawna
WHERE to_char(data_wyslania_sad, 'YYYY') NOT IN ('2013','2018')
GROUP BY 1
ORDER BY 1 DESC;

--najbardziej pracowite miesiace w dziale analiza_prawna (data wysylki do sadu)

SELECT to_char(data_wyslania_sad, 'MM') AS miesiac , COUNT(1) AS ilosc_wnioskow
FROM analiza_prawna
WHERE to_char(data_wyslania_sad, 'YYYY') NOT IN ('2013','2018')
GROUP BY 1
ORDER BY 2 DESC;


-- najbardziej pracowite dni (data wysylki do sadu)

SELECT to_char(data_wyslania_sad, 'ID') AS dzien_tygodnia , COUNT(1) FROM analiza_prawna
WHERE to_char(data_wyslania_sad, 'YYYY') NOT IN ('2013','2018')
GROUP BY 1
ORDER BY 2 DESC;


-- najbardziej pracowite miesiace_lata

SELECT to_char(data_wyslania_sad, 'YYYY-MM') AS rok_miesiac , COUNT(1) AS ilosc_wnioskow
FROM analiza_prawna
WHERE to_char(data_wyslania_sad, 'YYYY') NOT IN ('2013','2018')
GROUP BY 1
ORDER BY 2 DESC;

-- dni od daty utworzenia (wnioski poprawne) do daty rozpoczecia analizy w dziale a.pr
SELECT wp.id, wp.data_utworzenia, apr.data_rozpoczecia, (apr.data_rozpoczecia-wp.data_utworzenia) AS czas_trwania
FROM wnioski_poprawne wp JOIN analiza_prawna apr
ON wp.id=apr.id_wniosku
ORDER BY 4 DESC;

-- kwartyle czasu miedzy wplynieciem wniosku (data utworzenia z wnioskow poprawnych),
-- a data rozpoczenia wyslania wniosku do sadu

WITH tabela AS(
SELECT wp.id, wp.data_utworzenia, apr.data_wyslania_sad, date_part('day', apr.data_wyslania_sad-wp.data_utworzenia) AS czas_trwania
FROM wnioski_poprawne wp JOIN analiza_prawna apr
ON wp.id=apr.id_wniosku)

SELECT percentile_disc(0.25) WITHIN GROUP ( ORDER BY czas_trwania ) AS Q1,
       percentile_disc(0.5) WITHIN GROUP ( ORDER BY czas_trwania ) AS mediana,
       percentile_disc(0.75) WITHIN GROUP ( ORDER BY czas_trwania ) AS Q3

FROM tabela;



-- srednia ilosc dni od daty utworzenia (wnioski poprawne) do daty rozpoczecia analizy w dziale a.pr

SELECT AVG(date_part('day', apr.data_wyslania_sad - wp.data_utworzenia))
FROM wnioski_poprawne wp JOIN analiza_prawna apr
ON wp.id=apr.id_wniosku;



-- liczba wnioskow z analiza prawna, ktore zostana po joinie z wnioskami poprawnymi
--SELECT COUNT(wp.id) FROM wnioski_poprawne wp JOIN analiza_prawna ap ON wp.id=ap.id_wniosku
--WHERE data_utworzenia<data_rozpoczecia;



-- procentowa ilosc wnioskow w roku
SELECT to_char(ap.data_wyslania_sad, 'YYYY-MM') as data,
       to_char(ap.data_wyslania_sad, 'YYYY') as rok,
       to_char(ap.data_wyslania_sad, 'MM')as miesiac,
       count(*) as liczba_wnioskow,
       round(count() / sum(count()) over (partition by to_char(ap.data_wyslania_sad, 'YYYY')) * 100, 2) as procent_udzial_rok
FROM wnioski_poprawne wp
JOIN analiza_prawna ap on wp.id = ap.id_wniosku
WHERE to_char(ap.data_wyslania_sad, 'YYYY') NOT IN ('2013', '2018')
GROUP BY 1,2,3
ORDER BY liczba_wnioskow DESC;
