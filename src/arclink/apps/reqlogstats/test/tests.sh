#!/bin/sh
set -u

# Reqlogstats.py tests:
test_reqlogstats_quiet () {
	python ../reqlogstats.py -q < /dev/null > /tmp/q
	python ../reqlogstats.py -v < /dev/null > /tmp/v
	diff /tmp/q /tmp/v > /tmp/diffs

	rm -f /tmp/q /tmp/v /tmp/diffs
}

test_reqlogstats_noinput () {
	python -R -d ../reqlogstats.py < /dev/null > /tmp/1
	year=$(date +%Y)
	cat > /tmp/2 <<EOF
----------------------------------------------------------------------
Done with 0 file(s).
Scores:  0 rejected,  0 inserted,  0 not found,  0 unparseable,
Messages : 0
Network : 0
Report : 0
Request : 0
Source : 0
Station : 0
Summary : 0
User : 0
UserIP : 0
Volume : 0
Database $HOME/reqlogstats/var/reqlogstats-${year}.db contains  0 source(s), and 0 day summaries.
EOF
	diff /tmp/1 /tmp/2 && echo "No differences found" || cat /tmp/1
	rm -f /tmp/1 /tmp/2
}

test_splitmail_noinput () {
	python ../split_mail.py </dev/null > /tmp/1
	cat > /tmp/2 <<EOF
split_mail: 0 message(s) processed; 0 skipped, 0 written to $HOME/eida_stats

EOF
}

test_python_syntax () {
	grep -n --color -P '\t' ../*.py || echo "No tabs found in Python files."
	grep -n --color " \+$"  ../*.py || echo "No trailing white space found in Python files."
}

echo
echo "GENERAL PYTHON CHECKS"
echo

for t in test_reqlogstats_quiet test_reqlogstats_noinput test_splitmail_noinput test_python_syntax ; do
	$t
	echo "Done $t"
done
checkbashisms ../*.sh


# Tests which requre a meaningful database - small.db is derived from
# the active db on geofon-open2, with data for October-December 2014.

if [ 1 -eq 1 ] ; then

	echo
	echo "MAKE GRAPH CHECKS"
	echo

# make_month_graph

echo "SELECT distinct(networkCode),count(*) FROM ArcStatsNetwork GROUP BY networkCode;" | sqlite3 small.db

../make_month_graph.sh --code FN  8 2014 small.db  # No content in the db, so no output.
../make_month_graph.sh --code GE 12 2014 small.db
../make_month_graph.sh --code G  11 2014 small.db
../make_month_graph.sh --code CH 11 2014 small.db  # Present at two nodes, ODC and ETH

# Test with default database file: no file so no output.
../make_month_graph.sh 12 2014


../make_month_graph.sh 11 2014 small.db


fi


# make_year_graph

../make_year_graph.sh


# web content

test_web_content () {
	for f in ../www/*.php ; do
                php -l $f
		grep "+ PHP_EOL" $f  # Use '.' not '+'
        done

        php ../www/reqlog.php | wc -l  # expect 0
        php ../www/reqlogdisplay.php | file -  # expect XML
        php ../www/reqlognetwork.php | file -  # expect XML

}

test_web_code () {
    # Coding standard; see e.g.
    # https://en.wikibooks.org/wiki/PHP_Programming/Coding_Standards

    # Okay in HTML assignments but not PHP oens:
    grep -n --color "[^ ]=[^\"= ]" ../www/*.php

    # One space after control statements,
    # between the control keyword and opening parenthesis:
    grep -n --color "\(if\|for\|while\|switch\|foreach\)(" ../www/*.php

    # One space after commas, generally:
    grep -n --color ",[^ ]" ../www/*.php

    # Use one tab, no spaces (not 4, not 8)
    grep "        " ../www/*.php

}

if [ 1 -eq 1 ] ; then

	echo
	echo "WEB CONTENT CHECKS"
	echo

	test_web_content
	test_web_code
fi


# Unit test of t1.py, belongs higher up here...
python ../t1.py < /dev/null
# expect no errors, all values coverted to MiB

