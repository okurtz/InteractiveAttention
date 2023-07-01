using
    CSV,
    DataFrames,
    Logging,
    Printf,
    RData;

SOURCE_FILE_NAME = "Fiedler + Glöckner Daten/Eyelot2.dta";
OUTPUT_FILE_NAME = "Skripte/data/Study 2/Observations_Fiedler_Glöckner_2012_study_2_preprocessed.csv";

cd("C:\\Users\\Oliver\\Documents\\Studium\\Psychologie\\Bachelorarbeit");
iostream = open("preprocess_data.log", "w+");
logger = SimpleLogger(iostream);

rawData = load(SOURCE_FILE_NAME) |> DataFrame;

previousRowCount = size(rawData, 1);
rawData = filter(row -> isequal(row.ind, 2), rawData);
@info(@sprintf("Deleted %i rows that were not marked as actual observations (e.g., calibration runs, ind != 2).",
    previousRowCount - size(rawData, 1)));

previousRowCount = size(rawData, 1);
rowsWithMissingAOI = rawData[ismissing.(rawData.AOI), :];
@info(@sprintf("Deleted %i rows from %i participants where no information about the AOI fixated was given.",
    size(rowsWithMissingAOI, 1), size(unique(rowsWithMissingAOI[:, :trigger]), 1)));
rawData = filter(row -> !ismissing(row.AOI), rawData);

# Type conversion for later convenience
rawData[!,:subject] = Int32.(rawData[!,:subject]);

sort!(rawData, [:subject, :n]);
@info(@sprintf("Finished preprocessing. The preprocessed data set contains %i observations from %i participants and is sorted by participant and observation no. ascendingly.",
    size(rawData, 1), size(unique(rawData.subject), 1)));

CSV.write(OUTPUT_FILE_NAME, rawData);
@info(@sprintf("Preprocessed data was written to %s.", OUTPUT_FILE_NAME));

flush(iostream);
close(iostream);