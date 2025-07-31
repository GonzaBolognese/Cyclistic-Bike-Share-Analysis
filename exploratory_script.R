library(tidyverse)

Q1_2019 <- read.csv('Divvy_Trips_2019_Q1.csv')
Q2_2019 <- read.csv('Divvy_Trips_2019_Q2.csv')
Q3_2019 <- read.csv('Divvy_Trips_2019_Q3.csv')
Q4_2019 <- read.csv('Divvy_Trips_2019_Q4.csv')
Q1_2020 <- read.csv('Divvy_Trips_2020_Q1.csv')

# --- BLOQUE ÚNICO DE PREPARACIÓN DE DATOS ---

# 1. Estandarizar columnas en cada dataframe
Q1_2019_lean <- Q1_2019 %>%
  select(trip_id, start_time, end_time, rideable_type = bikeid, start_station_name = from_station_name, start_station_id = from_station_id, end_station_name = to_station_name, end_station_id = to_station_id, user_type = usertype) %>%
  mutate(across(c(trip_id, rideable_type, start_station_id, end_station_id), as.character))

Q2_2019_lean <- Q2_2019 %>%
  select(trip_id = `X01...Rental.Details.Rental.ID`, start_time, end_time, rideable_type = `X01...Rental.Details.Bike.ID`, start_station_name = `X03...Rental.Start.Station.Name`, start_station_id = `X03...Rental.Start.Station.ID`, end_station_name = `X02...Rental.End.Station.Name`, end_station_id = `X02...Rental.End.Station.ID`, user_type = `User.Type`) %>%
  mutate(across(c(trip_id, rideable_type, start_station_id, end_station_id), as.character))

Q3_2019_lean <- Q3_2019 %>%
  select(trip_id, start_time, end_time, rideable_type = bikeid, start_station_name = from_station_name, start_station_id = from_station_id, end_station_name = to_station_name, end_station_id = to_station_id, user_type = usertype) %>%
  mutate(across(c(trip_id, rideable_type, start_station_id, end_station_id), as.character))

Q4_2019_lean <- Q4_2019 %>%
  select(trip_id, start_time, end_time, rideable_type = bikeid, start_station_name = from_station_name, start_station_id = from_station_id, end_station_name = to_station_name, end_station_id = to_station_id, user_type = usertype) %>%
  mutate(across(c(trip_id, rideable_type, start_station_id, end_station_id), as.character))

Q1_2020_lean <- Q1_2020 %>%
  select(trip_id = ride_id, start_time, end_time, rideable_type, start_station_name, start_station_id, end_station_name, end_station_id, user_type = member_casual) %>%
  mutate(across(c(trip_id, rideable_type, start_station_id, end_station_id), as.character))

# 2. Unir todos los dataframes limpios
all_trips <- bind_rows(Q1_2019_lean, Q2_2019_lean, Q3_2019_lean, Q4_2019_lean, Q1_2020_lean)

# 3. Crear las columnas finales de análisis
all_trips <- all_trips %>%
  mutate(
    start_time_dt = ymd_hms(start_time),
    end_time_dt = ymd_hms(end_time),
    ride_length_mins = round(difftime(end_time_dt, start_time_dt, units = "mins"), 2),
    day_of_week = wday(start_time_dt, label = TRUE, abbr = FALSE)
  )

# 4. Verificar el resultado final
print("El dataframe 'all_trips' ha sido creado exitosamente. Estas son las columnas:")
print(colnames(all_trips))
# Eliminamos los dataframes que ya no son necesarios

rm(Q1_2019, Q1_2019_lean, 
   Q2_2019, Q2_2019_lean,
   Q3_2019, Q3_2019_lean,
   Q4_2019, Q4_2019_lean,
   Q1_2020, Q1_2020_lean)

# Calculamos la media, mediana, máximo y mínimo de la duración de los viajes.
# Nota: Usamos na.rm = TRUE para ignorar posibles valores NA en los cálculos.

summary_stats <- all_trips %>%
  summarise(
    mean_ride_length = mean(ride_length_mins, na.rm = TRUE),
    median_ride_length = median(ride_length_mins, na.rm = TRUE),
    max_ride_length = max(ride_length_mins, na.rm = TRUE),
    min_ride_length = min(ride_length_mins, na.rm = TRUE)
  )

print(summary_stats)

# Agrupamos por tipo de usuario y calculamos el promedio de duración y el número de viajes.

analysis_by_usertype <- all_trips %>%
  group_by(user_type) %>%
  summarise(
    number_of_rides = n(),
    average_duration_mins = mean(ride_length_mins, na.rm = TRUE)
  )

print(analysis_by_usertype)

# Agrupamos por tipo de usuario y día de la semana

analysis_by_day <- all_trips %>%
  group_by(user_type, day_of_week) %>%
  summarise(
    number_of_rides = n(),
    average_duration_mins = mean(ride_length_mins, na.rm = TRUE)
  ) %>%
  arrange(user_type, day_of_week)

print(analysis_by_day)

rm(all_trips,analysis_by_day,
   analysis_by_usertype, summary_stats
   )

# Se crea un nuevo dataframe limpio:
# 1. Se filtran las duraciones de viaje ilógicas.
# 2. Se unifican las categorías de tipo de usuario.

all_trips_clean <- all_trips %>%
  filter(ride_length_mins > 1 & ride_length_mins < 1440) %>%
  mutate(user_type_clean = case_when(
    user_type %in% c("Subscriber", "member") ~ "member",
    user_type %in% c("Customer", "casual") ~ "casual"
  ))

# Se vuelven a ejecutar los análisis sobre el dataframe limpio
analysis_by_usertype_clean <- all_trips_clean %>%
  group_by(user_type_clean) %>%
  summarise(
    number_of_rides = n(),
    average_duration_mins = mean(ride_length_mins, na.rm = TRUE)
  )

analysis_by_day_clean <- all_trips_clean %>%
  group_by(user_type_clean, day_of_week) %>%
  summarise(
    number_of_rides = n(),
    average_duration_mins = mean(ride_length_mins, na.rm = TRUE)
  )

# Se imprimen los resultados limpios
print("Análisis por tipo de usuario (Limpio):")
print(analysis_by_usertype_clean)
print("Análisis por día de la semana (Limpio):")
print(analysis_by_day_clean)
