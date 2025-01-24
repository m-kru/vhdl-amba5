class SLVERR(Exception):
    pass

class SerialBridge:
    _READ = 0b000
    _WRITE = 0b001
    _BLOCK_READ = 0b010
    _BLOCK_WRITE = 0b011
    _CYCLIC_READ = 0b100
    _CYCLIC_WRITE = 0b101
    _RMW = 0b110

    def __init__(self, addr_byte_count, iface):
        """
        Class allowing to access APB via the serial bridge.

        addr_byte_count:
            Number of used address bytes. This value must correspond to the
            value configured for the VHDL description. Otherwise, the interface
            will not work correctly.
        iface: An interface providing read and write methods for serial access.
        """
        self.addr_byte_count = addr_byte_count
        self.iface = iface

    def read(self, addr):
        """Read data from a single register.

        addr: Register address, not byte address!
        """
        addr <<= 2 # Shift to byte address

        assert 0 <= addr < 2 ** (8 * self.addr_byte_count) - 1, f"addr overrange"

        tx_buf = [self._READ << 5]
        for i in reversed(range(self.addr_byte_count)):
            tx_buf.append((addr >> i * 8) & 0xFF)

        self.iface.write(bytes(tx_buf))

        status = self.iface.read(1)[0]
        if (status & 0x80) != 0:
            raise SLVERR(f"read: addr {addr:#08X}")

        rx_buf = self.iface.read(4)

        return int.from_bytes(rx_buf, byteorder='big')

    def write(self, addr, data):
        """Write data to a single register.

        addr: Register address, not byte address!
        data: Data value.
        """
        addr <<= 2 # Shift to byte address

        assert 0 <= addr < 2 ** (8 * self.addr_byte_count) - 1, f"addr overrange"
        assert 0 <= data < 2 ** 32 - 1, f"data overrange"

        tx_buf = [self._WRITE << 5]
        for i in reversed(range(self.addr_byte_count)):
            tx_buf.append((addr >> i * 8) & 0xFF)
        for i in reversed(range(4)):
            tx_buf.append((data >> i * 8) & 0xFF)

        self.iface.write(bytes(tx_buf))

        status = self.iface.read(1)[0]
        if (status & 0x80) != 0:
            raise SLVERR(f"write: addr {addr:#08X}, data {data:#08X}")

        return