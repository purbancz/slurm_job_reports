# Slurm Monthly CSV Reports

Utility script for generating monthly Slurm accounting reports with `sacct`.

The script creates one CSV report per user, month and grant. It is designed to be run manually or periodically from `cron`.

## Suggested repository location

It is reccomended to locate the script in the `utils` folder in the shared storage of a project. For exaple, for the `plgproject` project:

```text
/net/storage/prX/plgrid/plgproject/_utils/slurm_reports
```

Generated reports are stored in the output directory under:

```text
logs/YYYY-MM/$USER-YYYY-MM.csv         without --grant
logs/YYYY-MM/$USER-YYYY-MM-GRANT.csv   with --grant
```

With this layout and the default option, e.g.:


```text
/net/storage/prX/plgrid/plgproject/_utils/slurm_reports
├── slurm_monthly_reports.sh
├── README.md
├── .gitignore
└── logs/
    ├── 2026-06/
    │   ├── username-2026-06.csv
    │   └── username-2026-06-grant_name100k-cpu.csv
    └── 2026-07/
        ├── username-2026-07.csv
        └── username-2026-07-grant_name100k-cpu.csv
```

## Requirements

The script requires:

* Bash
* GNU `date`
* Slurm `sacct`
* access to the Slurm accounting database

## Usage

```bash
./slurm_monthly_reports.sh [--output-path PATH] [--grant GRANT] [--month YYYY-MM]
```

All arguments are optional.

### `--output-path PATH`

Root path where the `logs/` directory will be created.
By default, the directory containing the script itself is used.


### `--grant GRANT`

Optional Slurm account/grant filter.
If omitted, the script does not pass `--accounts` to `sacct`, so all jobs visible to `sacct` for the current user are included.

When a grant is given, it is appended to the output filename, so the same user can report several grants for the same month without one overwriting another.

Example:

```bash
./slurm_monthly_reports.sh \
    --grant grant_name
```

writes `logs/2026-07/username-2026-07-grant_name.csv`.

Multiple Slurm accounts may be supplied if supported by the local `sacct` configuration, for example:

```bash
./slurm_monthly_reports.sh \
    --grant "grant_name100k-cpu,grant_name100k-cpu-bigmem"
```

Characters that are awkward in filenames — the comma separating multiple accounts, above all — are replaced with `_`, giving
`username-2026-07-grant_name100k-cpu_grant_name100k-cpu-bigmem.csv`.
The unmodified grant string is still what gets passed to `sacct`.

### `--month YYYY-MM`

Month to report. 
If omitted, the previous calendar month is used automatically.

To generate a report for a specific month:

```bash
./slurm_monthly_reports.sh \
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
15 6 1 * * /net/storage/prX/plgrid/plgproject/_utils/slurm_reports/slurm_monthly_reports.sh
```

Each user should run the script from their own cron environment.

To report several grants separately, add one line per grant — the grant in the filename keeps the reports apart:

```cron
15 6 1 * * /net/storage/prX/plgrid/plgproject/_utils/slurm_reports/slurm_monthly_reports.sh --grant grant_name100k-cpu
20 6 1 * * /net/storage/prX/plgrid/plgproject/_utils/slurm_reports/slurm_monthly_reports.sh --grant grant_name100k-cpu-bigmem
```



If cron output should also be retained, it can be redirected separately:

```cron
15 6 1 * * /net/storage/prX/plgrid/plgproject/_utils/slurm_reports/slurm_monthly_reports.sh >> /path/to/slurm_monthly_reports.log 2>&1
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

