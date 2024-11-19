uniffi::include_scaffolding!("lib");

use std::sync::{Arc, RwLock};
use std::cell::RefCell;

// pub enum Error {
//     ParseError(cel_interpreter::ParseError),
//     ExecutionError(cel_interpreter::ExecutionError),
// }
use std::error::Error;

pub type ExecutionError = cel_interpreter::ExecutionError;
// pub type ParseError = cel_interpreter::ParseError;
pub type ParseError = cel_interpreter::ParseError;
// pub type Value = cel_interpreter::Value;
pub type Program = cel_interpreter::Program;

pub struct Executor {
    context: Arc<RefCell<RwLock<cel_interpreter::Context<'static>>>>
}

pub enum Value {
    Bytes { value: Vec<u8> },
    List { value: Vec<Value> },
    Int { value: i64 },
    UInt { value: u64 },
    Float { value: f64 },
    String { value: String },
    Bool { value: bool },
    Null,
}

impl From<cel_interpreter::Value> for Value {
    fn from(value: cel_interpreter::Value) -> Self {
        match value {
            cel_interpreter::Value::Function(_, _) => todo!(),
            cel_interpreter::Value::Map(_) => todo!(),
            cel_interpreter::Value::Bytes(value) => Value::Bytes { value: Arc::unwrap_or_clone(value) },
            cel_interpreter::Value::List(value) => Value::List { value: value.iter().map(|val| val.clone().into()).collect::<Vec<Value>>() },
            cel_interpreter::Value::Int(value) => Value::Int { value },
            cel_interpreter::Value::UInt(value) => Value::UInt { value },
            cel_interpreter::Value::Float(value) => Value::Float { value },
            cel_interpreter::Value::String(value) => Value::String { value: value.to_string() },
            cel_interpreter::Value::Bool(value) => Value::Bool { value },
            cel_interpreter::Value::Null => Value::Null,
        }
    }
}

impl Into<cel_interpreter::Value> for Value {
    fn into(self) -> cel_interpreter::Value {
        use cel_interpreter::Value as CelValue;

        match self {
            Value::Bytes{value} => CelValue::Bytes(Arc::new(value.clone())),
            Value::List{value} => CelValue::List(Arc::new(value.into_iter().map(|val| (val).into()).collect::<Vec<CelValue>>())),
            Value::Int{value} => CelValue::Int(value),
            Value::UInt{value} => CelValue::UInt(value),
            Value::Float{value} => CelValue::Float(value),
            Value::String{value} => CelValue::String(Arc::new(value.clone())),
            Value::Bool{value} => CelValue::Bool(value),
            Value::Null => CelValue::Null,
        }
    }
}

#[allow(non_snake_case)]
mod fns {
    use std::sync::Arc;

    use cel_interpreter::extractors::This;
    use cel_interpreter::{Value, ExecutionError};

    type Result<T> = std::result::Result<T, ExecutionError>;

    // TODO: replace with string()
    fn value_to_string(value: &Value) -> Result<Arc<String>> {
        match value {
            Value::Function(_, _) |
            Value::Map(_) |
            Value::Bytes(_) |
            Value::List(_) => Err(ExecutionError::not_supported_as_method("string", value.clone())),
            Value::Int(int) => Ok(Arc::new(int.to_string())),
            Value::UInt(uint) => Ok(Arc::new(uint.to_string())),
            Value::Float(float) => Ok(Arc::new(float.to_string())),
            Value::String(str) => Ok(str.clone()),
            Value::Bool(bool) => Ok(Arc::new(bool.to_string())),
            Value::Null => Ok(Arc::new(String::from(""))),
        }
    }

    pub fn join(This(s): This<Value>, separator: Arc<String>) -> Result<Arc<String>> {
        return match s {
            Value::List(list) => {
                let string_list = list.iter()
                    .map(|v| value_to_string(v))
                    .collect::<Result<Vec<Arc<String>>>>();
                string_list
                    .map(|list| Arc::new(
                        list.iter()
                            .map(|v| v.as_str())
                            .collect::<Vec<&str>>()
                            .as_slice()
                            .join(separator.as_str())
                    ))
            },
            // Value::Map(_) => todo!(),
            _ => Err(ExecutionError::not_supported_as_method("join", s))
        };
    }

    pub fn r#if(condition: bool, value_if_true: Value, value_if_false: Value) -> Result<Value> {
        if condition {
            Ok(value_if_true)
        } else {
            Ok(value_if_false)
        }
    }

    pub fn substring(This(s): This<Arc<String>>, start: u64, end: u64) -> Result<Arc<String>> {
        Ok(Arc::new(s[(start as usize)..(end as usize)].to_string()))
    }

    pub fn left_discard(This(s): This<Arc<String>>, len: Value) -> Result<Arc<String>> {
        match len {
            Value::Int(i) => {
                if s.len() >= i as usize {
                    Ok(Arc::new(s[(i as usize)..].to_string()))
                } else {
                    Ok(String::from("").into())
                }
            },
            Value::UInt(i) => {
                if s.len() >= i as usize {
                    Ok(Arc::new(s[(i as usize)..].to_string()))
                } else {
                    Ok(String::from("").into())
                }
            },
            _ => Err(ExecutionError::UnexpectedType { got: format!("{:?}", len), want: String::from("Integer") })
        }
    }

    // TODO:
    // pub fn lowercase()
    // TODO: snake case, camel case, etc.
}

unsafe impl Send for Executor {}
unsafe impl Sync for Executor {}

impl Executor {
    pub fn new() -> Self {
        let mut context = cel_interpreter::Context::default();
        // context.add_function("toString", fns::toString);
        context.add_function("join", fns::join);
        context.add_function("if", fns::r#if);
        context.add_function("substring", fns::substring);
        context.add_function("leftDiscard", fns::left_discard);

        Self { context: Arc::new(RefCell::new(RwLock::new(context))) }
    }

    pub fn execute(&self, program: &cel_interpreter::Program) -> Result<Value, ExecutionError> {
        program.execute(&self.context.borrow().read().unwrap()).map(|v| v.into())
    }

    // pub fn set_string_var(&mut self, variable_name: &str, value: &str) -> Result<(), Box<dyn Error>> {
    //     self.context.write().unwrap().add_variable(variable_name, value)
    // }

    pub fn set_var(&self, variable_name: &str, value: Value) {
        self.context
            .borrow_mut()
            .write().unwrap()
            .add_variable(variable_name, Into::<cel_interpreter::Value>::into(value)).unwrap()
    }

    // pub fn execute(&self, code: &str) -> Result<Value, Error> {
    //     let program = match cel_interpreter::Program::compile(code) {
    //         Ok(prog) => prog,
    //         Err(err) => return Err(Error::ParseError(err)),
    //     };

    //     return self.execute_program(program);
    // }
}
