using
    CSV,
    DataFrames,
    RData;

const GAMBLE_COLUMNS = [:trigger, :Av1, :Ap1, :Av2, :Ap2, :Bv1, :Bp1, :Bv2, :Bp2];
const OUTPUT_FILE_NAME = "Gambles_Fiedler_Glöckner_2012.csv";

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit\\Skripte");
rawData = load("Fiedler + Glöckner Daten/Eyelot1.dta") |> DataFrame;
rawData = rawData[!, GAMBLE_COLUMNS] |> unique |> dropmissing |> sort;
CSV.write(OUTPUT_FILE_NAME, rawData);