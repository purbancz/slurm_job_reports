# Slurm Monthly CSV Reports

Utility script for generating monthly Slurm accounting reports with `sacct`.

The script creates one CSV report per user and month. It is designed to be run manually or periodically from `cron`.

## Suggested repository location

It is reccomended to locate the script in the `utils` folder in the shared storage of a project. For exaple, for the `plgproject` project:

```text
/net/storage/prX/plgrid/plgproject/_utils/slurm_reports
```

Generated reports are stored in output dierectory under:

```text
logs/YYYY-MM/$USER-YYYY-MM.csv
```

With this layout and the default option, e.g.:


```text
/net/storage/prX/plgrid/plgproject/_utils/slurm_reports
├── slurm_monthly_csv.sh
├── README.md
├── .gitignore
└── logs/
    ├── 2026-06/
    │   └── username-2026-06.csv
    └── 2026-07/
        └── username-2026-07.csv
```

## Requirements

The script requires:

* Bash
* GNU `date`
* Slurm `sacct`
* access to the Slurm accounting database

## Usage

```bash
./slurm_monthly_csv.sh [--output-path PATH] [--grant GRANT] [--month YYYY-MM]
```

All arguments are optional.

### `--output-path PATH`

Root path where the `logs/` directory will be created.
By default, the directory containing the script itself is used.


### `--grant GRANT`

Optional Slurm account/grant filter.
If omitted, the script does not pass `--accounts` to `sacct`, so all jobs visible to `sacct` for the current user are included.

Example:

```bash
./slurm_monthly_csv.sh \
    --grant grant_name
```

Multiple Slurm accounts may be supplied if supported by the local `sacct` configuration, for example:

```bash
./slurm_monthly_csv.sh \
    --grant "grant_name100k-cpu,grant_name100k-cpu-bigmem"
```

### `--month YYYY-MM`

Month to report. 
If omitted, the previous calendar month is used automatically.

To generate a report for a specific month:

```bash
./slurm_monthly_csv.sh \
    --month 2026-06
```


## Output format

The generated CSV contains the following columns:

```text
JobID
JobName
User
Account
State
Submit
Start
End
Elapsed
ReqMem
MaxRSS
```

Example header:

```csv
JobID,JobName,User,Account,State,Submit,Start,End,Elapsed,ReqMem,MaxRSS
```


## Automatic execution with cron

The script is intended to support monthly execution from `cron`.

For example, to run it on the first day of every month at 06:15:

```cron
15 6 1 * * /net/storage/prX/plgrid/plgproject/_utils/slurm_reports/slurm_monthly_csv.sh
```

Each user should run the script from their own cron environment.



If cron output should also be retained, it can be redirected separately:

```cron
15 6 1 * * /net/storage/prX/plgrid/plgproject/_utils/slurm_reports/slurm_monthly_csv.sh >> /path/to/slurm_monthly_csv.log 2>&1
```

## File permissions

The script uses:

```bash
umask 0002
```

This normally results in:

* files writable by owner and group
* directories writable by owner and group

As the script is meant to be stored in shared project directory.

Typical resulting permissions are:

```text
files:       664  rw-rw-r--
directories: 775  rwxrwxr-x
```

