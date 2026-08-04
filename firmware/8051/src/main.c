#include <reg52.h>
#include <stdio.h>

// Define pins
sbit LED1 = P2^1;    // LED connected to P2.1
sbit LED2 = P2^4;    // LED connected to P2.4
sbit LED3 = P2^7;    // LED connected to P2.7
sbit RELAY = P1^0;   // Relay connected to P1.0
sbit SERVO = P1^6;   // Servo connected to P1.6

// Variables
unsigned char receivedData;
unsigned int servoPosition = 14; // Default servo position (middle position ~90°)

// Function prototypes
void UART_Init(void);
unsigned char UART_ReceiveChar(void);
void UART_SendChar(unsigned char);
void UART_SendString(unsigned char*);
void servoControl(unsigned int);
void processCommand(unsigned char);
void delay_us(unsigned int);

void main()
{
    // Initialize UART for HC-05 communication
    UART_Init();
    
    // Initialize all outputs
    LED1 = 0;
    LED2 = 0;
    LED3 = 0;
    RELAY = 0;
    SERVO = 0;
    
    // Send initial status message
    UART_SendString("System Ready\r\n");
    
    while(1)
    {
        // Check if data is available
        if (RI == 1)
        {
            // Receive data from HC-05
            receivedData = UART_ReceiveChar();
            
            // Process the received command
            processCommand(receivedData);
        }
        
        // Control servo based on current position
        servoControl(servoPosition);
    }
}

// Initialize UART with 9600 baud rate (with 11.0592MHz crystal)
void UART_Init(void)
{
    TMOD = 0x21;  // Timer 1, Mode 2 (8-bit auto-reload) and Timer 0, Mode 1 (16-bit)
    TH1 = 0xFD;   // 9600 baud rate with 11.0592MHz crystal
    SCON = 0x50;  // 8-bit data, 1 stop bit, REN enabled
    TR1 = 1;      // Start Timer 1
}

// Receive character from UART
unsigned char UART_ReceiveChar(void)
{
    unsigned char receivedChar;
    receivedChar = SBUF;  // Get the received byte
    RI = 0;               // Clear receive interrupt flag
    return receivedChar;
}

// Send character through UART
void UART_SendChar(unsigned char sendChar)
{
    SBUF = sendChar;  // Load data into buffer
    while(TI == 0);   // Wait until transmission is complete
    TI = 0;           // Clear transmit interrupt flag
}

// Send string through UART
void UART_SendString(unsigned char *str)
{
    while(*str)
    {
        UART_SendChar(*str++);
    }
}

// Microsecond delay function using Timer 0
void delay_us(unsigned int us_count)
{
    // Using Timer 0 in 16-bit mode
    // For 11.0592 MHz crystal, 1 machine cycle = 1.085 us
    // So to get 1 us delay, we need to count approximately 0.922 machine cycles
    
    us_count = (us_count * 92) / 100;  // Adjust for actual delay
    
    TR0 = 0;  // Stop Timer 0
    TF0 = 0;  // Clear overflow flag
    
    // Set initial timer value
    TH0 = (65536 - us_count) >> 8;
    TL0 = (65536 - us_count) & 0xFF;
    
    TR0 = 1;  // Start Timer 0
    
    while(!TF0);  // Wait for timer overflow
    
    TR0 = 0;  // Stop Timer 0
    TF0 = 0;  // Clear overflow flag
}

// Control servo position using PWM
void servoControl(unsigned int position)
{
    // Generate 50Hz PWM signal (20ms period)
    // Pulse width varies from ~0.5ms (0°) to ~2.4ms (180°)
    
    SERVO = 1;  // Set servo pin high
    
    // Position value directly corresponds to pulse width in 0.1ms units
    // position = 5 means 0.5ms pulse (0°)
    // position = 14 means 1.4ms pulse (90°)
    // position = 24 means 2.4ms pulse (180°)
    delay_us(position * 100);
    
    SERVO = 0;  // Set servo pin low
    
    // Complete the 20ms cycle (remaining time)
    delay_us(20000 - (position * 100));
}

// Process received commands
void processCommand(unsigned char command)
{
    switch(command)
    {
        case '1':
            LED1 = !LED1;  // Toggle LED1
            if(LED1)
                UART_SendString("LED1 ON\r\n");
            else
                UART_SendString("LED1 OFF\r\n");
            break;
            
        case '2':
            LED2 = !LED2;  // Toggle LED2
            if(LED2)
                UART_SendString("LED2 ON\r\n");
            else
                UART_SendString("LED2 OFF\r\n");
            break;
            
        case '3':
            LED3 = !LED3;  // Toggle LED3
            if(LED3)
                UART_SendString("LED3 ON\r\n");
            else
                UART_SendString("LED3 OFF\r\n");
            break;
            
        case 'R':
            RELAY = !RELAY;  // Toggle Relay
            if(RELAY)
                UART_SendString("RELAY ON\r\n");
            else
                UART_SendString("RELAY OFF\r\n");
            break;
            
        case '0':
            servoPosition = 5;  // Set servo to 0° (0.5ms pulse)
            UART_SendString("Servo at 0 degrees\r\n");
            break;
            
        case '9':
            servoPosition = 14;  // Set servo to 90° (1.4ms pulse)
            UART_SendString("Servo at 90 degrees\r\n");
            break;
            
        case 'A':
            if(servoPosition < 24)  // Increase servo angle (limit to max 180°)
                servoPosition++;
            UART_SendString("Servo +\r\n");
            break;
            
        case 'B':
            if(servoPosition > 5)   // Decrease servo angle (limit to min 0°)
                servoPosition--;
            UART_SendString("Servo -\r\n");
            break;
            
        default:
            UART_SendString("Unknown Command\r\n");
            break;
    }
}
