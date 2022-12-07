#include <signal.h>
#include <time.h>
#include <ctype.h>
#include <string.h>
#include <stdint.h>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vtop.h"

#include "testb.h"

class BLINKY_TB : public TESTB<Vtop>
{
	// {{{
public:
	unsigned long m_tx_busy_count;
	bool m_done;
	IData prev_LEDS;

	BLINKY_TB()
	{
		m_done = false;
	}

	void trace(const char *vcd_trace_file_name)
	{
		fprintf(stderr, "Opening TRACE(%s)\n", vcd_trace_file_name);
		opentrace(vcd_trace_file_name);
	}

	void close(void)
	{
		TESTB<Vtop>::closetrace();
	}

	void tick(void)
	{
		// {{{
		if (m_done)
			return;

		if (prev_LEDS != m_core->LEDS)
		{
			for (uint16_t i = sizeof(m_core->LEDS) << 3; i; i--)
			{
				putchar('0' + ((m_core->LEDS >> (i - 1)) & 1));
			}
			putchar('\n');
		}
		prev_LEDS = m_core->LEDS;

		TESTB<Vtop>::tick();
	}
	// }}}

	bool done(void)
	{
		// {{{
		if (m_done)
			return true;
		else
		{
			if (Verilated::gotFinish())
				m_done = true;
			return m_done;
		}
	}
	// }}}
};
// }}}

BLINKY_TB *tb;

int main(int argc, char **argv)
{
	// {{{
	Verilated::commandArgs(argc, argv);
	tb = new BLINKY_TB();

	//tb->opentrace("trace.vcd");
	tb->reset();

	while (!tb->done())
	{
		tb->tick();
	}

	tb->close();
	exit(0);
}
// }}}
