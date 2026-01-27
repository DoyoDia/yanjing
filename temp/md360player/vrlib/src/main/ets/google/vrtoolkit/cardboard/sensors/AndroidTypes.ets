export interface Sensor {
    getType(): number;
}

export interface SensorEvent {
    sensor: Sensor;
    values: number[];
    timestamp: number;
}

export interface SensorEventListener {
    onSensorChanged(event: SensorEvent): void;
    onAccuracyChanged(sensor: Sensor, accuracy: number): void;
}

export interface Handler {
}

export interface HandlerThread {
    start(): void;
    getLooper(): Looper;
}

export interface Looper {
    quit(): void;
}

export interface Build {
    MANUFACTURER: string;
}

export interface SensorManager {
    getDefaultSensor(type: number): Sensor | null;
    registerListener(listener: SensorEventListener, sensor: Sensor, rate: number, handler?: Handler): boolean;
    unregisterListener(listener: SensorEventListener): void;
}

export interface Context {
    getSystemService(name: string): Object;
}

export interface Display {
    getRotation(): number;
}

export interface WindowManager {
    getDefaultDisplay(): Display;
}
