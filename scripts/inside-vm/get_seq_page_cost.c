#include <time.h>
#include <stdio.h>

#define READ_REPETITIONS 100000
#define AVG_REPETITIONS 5

// BUFSIZE should be equal to 8KB, the PostgreSQL page size.
#define BUFSIZE 1024*8

#define FILEPATH "get_seq_page_cost.dat"

int main() {

    int i = 0, j;
    double average = 0;
    FILE *fp = fopen(FILEPATH,"r");
    char buf[BUFSIZE];

    clock_t start, end;
    double cpu_time_used;

    for( j = 0; j < AVG_REPETITIONS; j++ ) {
        start = clock();
        for( i = 0; i < READ_REPETITIONS; i++ ) {


            if ( fread(buf,sizeof(char),BUFSIZE,fp) == 0 )
                return -1;


        //    cpu_time_used = ((double) end - start  ) *  (1000 / CLOCKS_PER_SEC);
         //   average+=cpu_time_used;

            rewind(fp);
        }
        end = clock();
        cpu_time_used = 1000 * ( ( (double) end -  start ) / ( CLOCKS_PER_SEC ) );
        cpu_time_used/=READ_REPETITIONS;
        average+=cpu_time_used;
        printf("cpu_time: %lf\n",cpu_time_used);
    }
    average/=j;
    printf("%lf\n",average);
    return -1;

}
